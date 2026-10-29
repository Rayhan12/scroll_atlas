/// Seeded contact data: 26 letters, 3 to 40 people each.
library;

/// The section letters A to Z.
const List<String> contactLetters = <String>[
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

/// Real first names for each section letter.
const Map<String, List<String>> _firsts = <String, List<String>>{
  'A': <String>['Aisha', 'Arif', 'Amara', 'Anika'],
  'B': <String>['Bilal', 'Bianca', 'Bruno', 'Bushra'],
  'C': <String>['Chloe', 'Carlos', 'Chidi', 'Cyrus'],
  'D': <String>['Daniel', 'Dina', 'Deepa', 'Dario'],
  'E': <String>['Elena', 'Emeka', 'Ethan', 'Esra'],
  'F': <String>['Farhan', 'Fatima', 'Felix', 'Freya'],
  'G': <String>['Grace', 'Gabriel', 'Gita', 'Goran'],
  'H': <String>['Hana', 'Hamid', 'Hugo', 'Helga'],
  'I': <String>['Imran', 'Ines', 'Ivan', 'Ishita'],
  'J': <String>['Jamal', 'Julia', 'Jun', 'Jasmine'],
  'K': <String>['Kamal', 'Keiko', 'Kofi', 'Karin'],
  'L': <String>['Leila', 'Lucas', 'Lina', 'Luka'],
  'M': <String>['Maya', 'Mahir', 'Marco', 'Mei'],
  'N': <String>['Nadia', 'Nabil', 'Nora', 'Nikhil'],
  'O': <String>['Omar', 'Olga', 'Oscar', 'Oluchi'],
  'P': <String>['Priya', 'Pablo', 'Pia', 'Parvez'],
  'Q': <String>['Qasim', 'Quinn', 'Qing'],
  'R': <String>['Rafi', 'Rosa', 'Ravi', 'Rina'],
  'S': <String>['Sara', 'Samir', 'Sofia', 'Sven'],
  'T': <String>['Tanvir', 'Tara', 'Theo', 'Tomoko'],
  'U': <String>['Usman', 'Uma', 'Ulrich', 'Ursula'],
  'V': <String>['Vera', 'Vikram', 'Victor', 'Vanya'],
  'W': <String>['Wahid', 'Wendy', 'Wei', 'Willem'],
  'X': <String>['Xavier', 'Ximena', 'Xin'],
  'Y': <String>['Yusuf', 'Yara', 'Yuki', 'Yasmin'],
  'Z': <String>['Zara', 'Zayan', 'Zoe', 'Zoltan'],
};

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

const List<String> _roles = <String>[
  'Product designer',
  'Flutter engineer',
  'Engineering manager',
  'Data scientist',
  'QA lead',
  'Founder',
  'Marketing lead',
  'Backend engineer',
];

const List<String> _companies = <String>[
  'Pathao',
  'bKash',
  'Grameenphone',
  'Shopify',
  'Canva',
  'Spotify',
  'Klarna',
  'Wise',
];

const List<String> _notes = <String>[
  'Met at Flutter Dhaka meetup',
  'Prefers WhatsApp, not calls',
  'Birthday in March',
  'Shared the design system doc',
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
  final firsts = _firsts[letter]!;
  final name = '${firsts[index % firsts.length]} '
      '${_families[(index ~/ firsts.length + seed) % _families.length]}';
  final lines = 1 + seed % 3;
  final note = <String>[
    '${_roles[seed % _roles.length]} at '
        '${_companies[(seed ~/ 3) % _companies.length]}',
    if (lines > 1)
      '+880 1${(700000000 + seed * 9973 % 99999999).toString().substring(0, 3)}'
          ' ${(seed * 7 % 900000 + 100000)}',
    if (lines > 2) _notes[seed % _notes.length],
  ].join('\n');
  return Contact(name: name, note: note);
}
