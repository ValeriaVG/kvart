//! i18n codegen.
//!
//! Reads `i18n/<locale>.toml`, emits:
//!   * a consolidated `Localizable.xcstrings` catalog for iOS
//!   * a Swift `L10n` enum giving each key a compile-time constant
//!
//! `en.toml` is the canonical key set — missing keys in other locales warn,
//! extra keys error.

use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::{Path, PathBuf},
};

use clap::Parser;
use serde::{Deserialize, Serialize};
use anyhow::{bail, Context, Result};

#[derive(Parser)]
struct Args {
    /// Directory containing <locale>.toml files.
    #[arg(long)]
    input_dir: PathBuf,
    /// Destination for Localizable.xcstrings.
    #[arg(long)]
    xcstrings_out: PathBuf,
    /// Destination for generated Swift L10n enum.
    #[arg(long)]
    swift_out: PathBuf,
}

type Flat = BTreeMap<String, String>;

#[derive(Deserialize)]
#[serde(untagged)]
enum TomlNode {
    Leaf(String),
    Branch(BTreeMap<String, TomlNode>),
}

fn flatten(node: &TomlNode, prefix: &str, out: &mut Flat) {
    match node {
        TomlNode::Leaf(s) => {
            out.insert(prefix.to_string(), s.clone());
        }
        TomlNode::Branch(map) => {
            for (k, v) in map {
                let next = if prefix.is_empty() {
                    k.clone()
                } else {
                    format!("{prefix}.{k}")
                };
                flatten(v, &next, out);
            }
        }
    }
}

fn load_locale(path: &Path) -> Result<Flat> {
    let text = fs::read_to_string(path)
        .with_context(|| format!("reading {}", path.display()))?;
    let root: TomlNode = TomlNode::Branch(
        toml::from_str(&text).with_context(|| format!("parsing {}", path.display()))?,
    );
    let mut out = Flat::new();
    flatten(&root, "", &mut out);
    Ok(out)
}

// ---- xcstrings schema ----
#[derive(Serialize)]
struct Catalog {
    #[serde(rename = "sourceLanguage")]
    source_language: &'static str,
    strings: BTreeMap<String, Entry>,
    version: &'static str,
}

#[derive(Serialize)]
struct Entry {
    #[serde(skip_serializing_if = "Option::is_none")]
    comment: Option<String>,
    #[serde(rename = "extractionState")]
    extraction_state: &'static str,
    localizations: BTreeMap<String, Localization>,
}

#[derive(Serialize)]
struct Localization {
    #[serde(rename = "stringUnit")]
    string_unit: StringUnit,
}

#[derive(Serialize)]
struct StringUnit {
    state: &'static str,
    value: String,
}

fn write_xcstrings(locales: &BTreeMap<String, Flat>, en: &Flat, out: &Path) -> Result<()> {
    let mut strings = BTreeMap::new();
    for key in en.keys() {
        let mut localizations = BTreeMap::new();
        for (lang, map) in locales {
            if let Some(v) = map.get(key) {
                localizations.insert(
                    lang.clone(),
                    Localization {
                        string_unit: StringUnit {
                            state: "translated",
                            value: v.clone(),
                        },
                    },
                );
            }
        }
        strings.insert(
            key.clone(),
            Entry {
                comment: None,
                extraction_state: "manual",
                localizations,
            },
        );
    }
    let catalog = Catalog {
        source_language: "en",
        strings,
        version: "1.0",
    };
    if let Some(parent) = out.parent() {
        fs::create_dir_all(parent)?;
    }
    let json = serde_json::to_string_pretty(&catalog)?;
    fs::write(out, json + "\n")?;
    Ok(())
}

// ---- Swift L10n ----
fn swift_ident(s: &str) -> String {
    let mut out = String::new();
    let mut upper = false;
    for ch in s.chars() {
        if ch == '_' {
            upper = true;
        } else if upper {
            out.push(ch.to_ascii_uppercase());
            upper = false;
        } else {
            out.push(ch);
        }
    }
    out
}

fn type_name(s: &str) -> String {
    let id = swift_ident(s);
    let mut c = id.chars();
    c.next()
        .map(|ch| ch.to_ascii_uppercase().to_string() + c.as_str())
        .unwrap_or_default()
}

#[derive(Default)]
struct Tree {
    children: BTreeMap<String, Tree>,
    leaves: BTreeMap<String, (String, String)>, // ident -> (fullKey, english)
}

fn insert(tree: &mut Tree, parts: &[&str], full_key: &str, english: &str) {
    if let [last] = parts {
        tree.leaves.insert(
            swift_ident(last),
            (full_key.to_string(), english.to_string()),
        );
    } else {
        let head = parts[0];
        let child = tree.children.entry(head.to_string()).or_default();
        insert(child, &parts[1..], full_key, english);
    }
}

fn count_at_placeholders(s: &str) -> usize {
    let mut n = 0;
    let bytes = s.as_bytes();
    let mut i = 0;
    while i + 1 < bytes.len() {
        if bytes[i] == b'%' && bytes[i + 1] == b'@' {
            n += 1;
            i += 2;
        } else {
            i += 1;
        }
    }
    n
}

fn emit_swift(tree: &Tree, name: &str, depth: usize, out: &mut String) {
    let indent = "    ".repeat(depth);
    out.push_str(&format!("{indent}enum {name} {{\n"));
    let inner = "    ".repeat(depth + 1);
    for (ident, (key, english)) in &tree.leaves {
        let escaped = english.replace('\\', "\\\\").replace('"', "\\\"");
        let args = count_at_placeholders(english);
        if args == 0 {
            out.push_str(&format!(
                "{inner}static var {ident}: String {{ String(localized: \"{key}\", defaultValue: \"{escaped}\", bundle: LocaleBundle.current) }}\n"
            ));
        } else {
            let params: Vec<String> = (0..args)
                .map(|i| format!("_ arg{i}: CVarArg"))
                .collect();
            let call_args: Vec<String> = (0..args).map(|i| format!("arg{i}")).collect();
            out.push_str(&format!(
                "{inner}static func {ident}({}) -> String {{\n",
                params.join(", ")
            ));
            out.push_str(&format!(
                "{inner}    String(format: String(localized: \"{key}\", defaultValue: \"{escaped}\", bundle: LocaleBundle.current), {})\n",
                call_args.join(", ")
            ));
            out.push_str(&format!("{inner}}}\n"));
        }
    }
    for (child_name, child) in &tree.children {
        emit_swift(child, &type_name(child_name), depth + 1, out);
    }
    out.push_str(&format!("{indent}}}\n"));
}

fn write_swift(en: &Flat, out: &Path) -> Result<()> {
    let mut tree = Tree::default();
    for (key, english) in en {
        let parts: Vec<&str> = key.split('.').collect();
        insert(&mut tree, &parts, key, english);
    }
    let mut body = String::from(
        "// Generated by `cargo run --bin i18n`. Do not edit.\n\
         // Source: i18n/*.toml\n\n\
         import Foundation\n\n",
    );
    emit_swift(&tree, "L10n", 0, &mut body);
    if let Some(parent) = out.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(out, body)?;
    Ok(())
}

fn main() -> Result<()> {
    let args = Args::parse();

    let mut locales: BTreeMap<String, Flat> = BTreeMap::new();
    for entry in fs::read_dir(&args.input_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) != Some("toml") {
            continue;
        }
        let lang = path
            .file_stem()
            .and_then(|s| s.to_str())
            .context("bad locale filename")?
            .to_string();
        locales.insert(lang, load_locale(&path)?);
    }

    let en = locales
        .get("en")
        .context("en.toml is required (canonical key set)")?
        .clone();
    let en_keys: BTreeSet<&String> = en.keys().collect();

    for (lang, map) in &locales {
        if lang == "en" {
            continue;
        }
        let keys: BTreeSet<&String> = map.keys().collect();
        let missing: Vec<&&String> = en_keys.difference(&keys).collect();
        let extra: Vec<&&String> = keys.difference(&en_keys).collect();
        if !extra.is_empty() {
            bail!("{lang}.toml contains keys not in en.toml: {extra:?}");
        }
        if !missing.is_empty() {
            eprintln!("warning: {lang}.toml missing {} keys: {missing:?}", missing.len());
        }
    }

    write_xcstrings(&locales, &en, &args.xcstrings_out)?;
    write_swift(&en, &args.swift_out)?;
    println!(
        "i18n: {} keys, {} locales → {} + {}",
        en.len(),
        locales.len(),
        args.xcstrings_out.display(),
        args.swift_out.display(),
    );
    Ok(())
}
