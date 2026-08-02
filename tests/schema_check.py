#!/usr/bin/env python3
"""Minimal JSON Schema validator covering the subset used by the agent output
schemas (draft 2020-12): type, properties, required, additionalProperties,
items, enum, minimum/maximum. Dependency-free (stdlib only) so the tests run
anywhere python3 is available.

Not a general validator — it intentionally supports only the keywords the
agent schemas use. If a schema introduces a new keyword, extend this module
and add a fixture that exercises it.
"""
from __future__ import annotations

from typing import Any


def validate(data: Any, schema: dict, path: str = "$") -> list[str]:
    errors: list[str] = []

    if "type" in schema:
        t = schema["type"]
        ok = (
            (t == "object" and isinstance(data, dict))
            or (t == "array" and isinstance(data, list))
            or (t == "string" and isinstance(data, str))
            or (t == "integer" and isinstance(data, int) and not isinstance(data, bool))
            or (t == "number" and isinstance(data, (int, float)) and not isinstance(data, bool))
            or (t == "boolean" and isinstance(data, bool))
        )
        if not ok:
            errors.append(f"{path}: expected type {t}, got {type(data).__name__}")
            return errors

    if isinstance(data, dict):
        if "properties" in schema:
            for key, subschema in schema["properties"].items():
                if key in data:
                    errors.extend(validate(data[key], subschema, f"{path}.{key}"))
        for required in schema.get("required", []):
            if required not in data:
                errors.append(f"{path}: missing required property '{required}'")
        if schema.get("additionalProperties") is False:
            allowed = set(schema.get("properties", {}))
            for key in sorted(set(data) - allowed):
                errors.append(f"{path}: unexpected property '{key}' (additionalProperties: false)")

    elif isinstance(data, list):
        items = schema.get("items")
        if items:
            for index, item in enumerate(data):
                errors.extend(validate(item, items, f"{path}[{index}]"))

    if "enum" in schema and data not in schema["enum"]:
        errors.append(f"{path}: value {data!r} not in enum {schema['enum']}")

    if isinstance(data, (int, float)) and not isinstance(data, bool):
        if "minimum" in schema and data < schema["minimum"]:
            errors.append(f"{path}: {data} < minimum {schema['minimum']}")
        if "maximum" in schema and data > schema["maximum"]:
            errors.append(f"{path}: {data} > maximum {schema['maximum']}")

    return errors


def valid(data: Any, schema: dict) -> bool:
    return not validate(data, schema)
