class Vocab {
  final String id;
  final String en;
  final String vi;
  final bool userAdded;

  Vocab({
    required this.id,
    required this.en,
    required this.vi,
    this.userAdded = false,
  });

  factory Vocab.fromJson(Map<String, dynamic> json) {
    return Vocab(
      id: json['id']?.toString() ?? (json['en']?.toString() ?? ''),
      en: json['en']?.toString() ?? '',
      vi: json['vi']?.toString() ?? '',
      userAdded: json['userAdded'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'en': en,
    'vi': vi,
    'userAdded': userAdded,
  };
}
