/// JSON schema for validating Gemini AI image editor responses.
///
/// This schema defines the expected structure for AI output, including
/// optional and required fields like layers, filters, blur, tune, and
/// transform settings used in the editor.
const geminiResponseSchema = {
  'type': 'OBJECT',
  'properties': {
    'layers': {
      'nullable': true,
      'type': 'ARRAY',
      'items': {
        'type': 'OBJECT',
        'properties': {
          'x': {
            'type': 'NUMBER',
          },
          'y': {
            'type': 'NUMBER',
          },
          'rotation': {
            'type': 'NUMBER',
          },
          'scale': {
            'type': 'NUMBER',
          },
          'flipX': {'type': 'BOOLEAN'},
          'flipY': {'type': 'BOOLEAN'},
          'type': {'type': 'STRING'},
          'emoji': {
            'type': 'STRING',
            'nullable': true,
          },
          'text': {
            'type': 'STRING',
            'nullable': true,
          },
          'colorMode': {
            'type': 'STRING',
            'nullable': true,
          },
          'color': {
            'type': 'NUMBER',
            'nullable': true,
          },
          'background': {
            'type': 'NUMBER',
            'nullable': true,
          },
          'align': {
            'type': 'STRING',
            'nullable': true,
          },
          'fontScale': {
            'type': 'NUMBER',
            'nullable': true,
          },
          'rawSize': {
            'type': 'OBJECT',
            'properties': {
              'w': {'type': 'NUMBER'},
              'h': {'type': 'NUMBER'}
            },
            'required': ['w', 'h']
          },
          'item': {
            'type': 'OBJECT',
            'properties': {
              'offsets': {
                'type': 'ARRAY',
                'items': {
                  'type': 'object',
                  'properties': {
                    'x': {'type': 'number'},
                    'y': {'type': 'number'}
                  },
                  'required': ['x', 'y']
                },
                'minItems': 2
              },
              'mode': {'type': 'STRING'},
              'color': {'type': 'NUMBER'},
              'strokeWidth': {'type': 'NUMBER'},
              'opacity': {'type': 'NUMBER', 'minimum': 0.0, 'maximum': 1.0},
              'fill': {
                'type': 'BOOLEAN',
              },
            },
            'required': [
              'offsets',
              'mode',
              'color',
              'strokeWidth',
              'opacity',
              'fill'
            ],
            'nullable': true,
          },
        },
        'required': ['x', 'y', 'rotation', 'scale', 'flipX', 'flipY', 'type']
      }
    },
    'blur': {
      'nullable': true,
      'type': 'NUMBER',
    },
    'tune': {
      'nullable': true,
      'type': 'ARRAY',
      'items': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'value': {'type': 'number'},
          'matrix': {
            'type': 'ARRAY',
            'items': {'type': 'number'},
            'minItems': 20,
            'maxItems': 20
          }
        },
        'required': ['id', 'value', 'matrix']
      }
    },
    'filters': {
      'nullable': true,
      'type': 'ARRAY',
      'items': {
        'type': 'ARRAY',
        'items': {'type': 'number'},
        'minItems': 20,
        'maxItems': 20
      }
    },
    'transform': {
      'nullable': true,
      'type': 'OBJECT',
      'properties': {
        'angle': {
          'type': 'NUMBER',
        },
        'cropRect': {
          'type': 'OBJECT',
          'properties': {
            'left': {
              'type': 'NUMBER',
            },
            'top': {
              'type': 'NUMBER',
            },
            'right': {
              'type': 'NUMBER',
            },
            'bottom': {
              'type': 'NUMBER',
            }
          },
          'required': ['left', 'top', 'right', 'bottom']
        },
        'originalSize': {
          'type': 'OBJECT',
          'properties': {
            'width': {
              'type': 'NUMBER',
            },
            'height': {
              'type': 'NUMBER',
            }
          },
          'required': ['width', 'height']
        },
        'cropEditorScreenRatio': {
          'type': 'NUMBER',
        },
        'scaleUser': {
          'type': 'NUMBER',
        },
        'scaleRotation': {
          'type': 'NUMBER',
        },
        'aspectRatio': {
          'type': 'NUMBER',
        },
        'flipX': {'type': 'BOOLEAN'},
        'flipY': {'type': 'BOOLEAN'},
        'cropMode': {'type': 'STRING'},
        'offset': {
          'type': 'OBJECT',
          'properties': {
            'dx': {
              'type': 'NUMBER',
            },
            'dy': {
              'type': 'NUMBER',
            }
          },
          'required': ['dx', 'dy']
        }
      },
      'required': [
        'angle',
        'cropRect',
        'originalSize',
        'cropEditorScreenRatio',
        'scaleUser',
        'scaleRotation',
        'aspectRatio',
        'flipX',
        'flipY',
        'cropMode',
        'offset'
      ]
    }
  },
  'required': []
};
