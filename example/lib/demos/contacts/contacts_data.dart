/// Seeded contact data for D2: 26 letters, 3 to 40 people each.
library;

/// The section letters A to Z.
const List<String> contactLetters = <String>[
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

const List<String> _endings = <String>[
  'ara',
  'en',
  'ia',
  'on',
  'ika',
  'el',
  'ur',
  'ina',
  'is',
  'ani',
  'or',
  'ey',
];

const List<String> _families = <String>[
  'Rahman',
  'Chen',
  'Okafor',
  'Silva',
  'Novak',
  'Haddad',
  'Kim',
  'Moreau',
  'Ivanova',
  'Tanaka',
  'Mensah',
  'Larsen',
  'Gupta',
  'Alvarez',
  'Nguyen',
];

/// One contact.
final class Contact {
  /// Creates a contact.
  const Contact({required this.name, required this.note});

  /// Display name.
  final String name;

  /// Note of one to three lines, so tiles have different heights.
  final String note;
}

/// Number of contacts under [letter]: between 3 and 40.
int contactCount(String letter) => 3 + (letter.codeUnitAt(0) * 37) % 38;

/// Contact [index] under [letter], always the same for the same input.
Contact contactAt(String letter, int index) {
  final seed = letter.codeUnitAt(0) * 131 + index * 7919;
  final name = '$letter${_endings[seed % _endings.length]} '
      '${_families[(seed ~/ 7) % _families.length]}';
  final lines = 1 + seed % 3;
  final note = <String>[
    for (var line = 0; line < lines; line++)
      line == 0 ? 'Contact $letter $index' : 'Note line ${line + 1}',
  ].join('\n');
  return Contact(name: name, note: note);
}
