A2UI_SCHEMA = {
    "type": "array",
    "items": {
        "type": "object",
        "anyOf": [
            {
                "required": ["surfaceUpdate"],
                "properties": {
                    "surfaceUpdate": {
                        "type": "object",
                        "required": ["surfaceId", "components"],
                        "properties": {
                            "surfaceId": {"type": "string"},
                            "components": {"type": "array"},
                        },
                    }
                },
            },
            {
                "required": ["dataModelUpdate"],
                "properties": {
                    "dataModelUpdate": {
                        "type": "object",
                        "required": ["surfaceId", "contents"],
                        "properties": {
                            "surfaceId": {"type": "string"},
                            "contents": {"type": "array"},
                        },
                    }
                },
            },
            {
                "required": ["beginRendering"],
                "properties": {
                    "beginRendering": {
                        "type": "object",
                        "required": ["surfaceId", "root"],
                        "properties": {
                            "surfaceId": {"type": "string"},
                            "root": {"type": "string"},
                        },
                    }
                },
            },
        ],
    },
}
