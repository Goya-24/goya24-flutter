/// Who is signed in to the app, as the messenger is told.
///
/// With [id] and [hash] the identity is *proven*: your server signs the id
/// with the workspace's identity secret (`hmac_sha256(secret, id)`, hex),
/// and goya24 checks the signature before trusting a word. Without them the
/// details are still sent, as a claim — useful, and the inbox marks it as
/// one.
///
/// Never compute the hash in the app. The secret must not ship inside an
/// app bundle; the hash comes from your backend, usually with the session.
class Goya24User {
  /// A user by id, proven when [hash] is set.
  const Goya24User({
    required this.id,
    this.hash,
    this.name,
    this.email,
    this.plan,
  });

  /// Your own id for the user. This is what gets signed.
  final String id;

  /// `hmac_sha256(identitySecret, id)` as lowercase hex, computed on your
  /// server. Null sends the user as a claim.
  final String? hash;

  /// The name the agent greets them by.
  final String? name;

  /// Their email, for the inbox and for follow-ups.
  final String? email;

  /// A plan or tier name the agent may mention ("gold", "trial").
  final String? plan;

  /// Whether goya24 will treat this identity as proven.
  bool get isProven => hash != null && hash!.isNotEmpty;

  /// The query parameters the messenger reads — the same ones the web
  /// loader puts in the frame's address.
  Map<String, String> toQueryParameters() {
    final out = <String, String>{'uid': id};
    if (isProven) out['uhash'] = hash!;
    if (name != null && name!.isNotEmpty) out['uname'] = name!;
    if (email != null && email!.isNotEmpty) out['uemail'] = email!;
    if (plan != null && plan!.isNotEmpty) out['uplan'] = plan!;
    return out;
  }

  /// The payload of an `identify` message sent after boot — a claim, the
  /// way the web loader's `identify()` sends one.
  Map<String, Object?> toIdentifyPayload() => {
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (plan != null) 'plan': plan,
      };

  /// A copy with some fields changed.
  Goya24User copyWith({
    String? id,
    String? hash,
    String? name,
    String? email,
    String? plan,
  }) =>
      Goya24User(
        id: id ?? this.id,
        hash: hash ?? this.hash,
        name: name ?? this.name,
        email: email ?? this.email,
        plan: plan ?? this.plan,
      );

  @override
  bool operator ==(Object other) =>
      other is Goya24User &&
      other.id == id &&
      other.hash == hash &&
      other.name == name &&
      other.email == email &&
      other.plan == plan;

  @override
  int get hashCode => Object.hash(id, hash, name, email, plan);

  @override
  String toString() => 'Goya24User(id: $id, proven: $isProven)';
}
