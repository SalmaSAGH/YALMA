import 'dart:convert';

class User {
  final String fullName;
  final String email;
  final String password;
  final BankAccount? bankAccount;

  User({
    required this.fullName,
    required this.email,
    required this.password,
    this.bankAccount,
  });

  factory User.fromJson(Map<String, dynamic> jsonMap) {
    dynamic bankAccountJson = jsonMap['bankAccount'];
    BankAccount? bankAccount;

    if (bankAccountJson != null) {
      if (bankAccountJson is String) {
        bankAccount = BankAccount.fromJson(json.decode(bankAccountJson));
      } else if (bankAccountJson is Map<String, dynamic>) {
        bankAccount = BankAccount.fromJson(bankAccountJson);
      }
    }

    return User(
      fullName: jsonMap['fullName'] ?? '',
      email: jsonMap['email'] ?? '',
      password: jsonMap['password'] ?? '',
      bankAccount: bankAccount,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'bankAccount': bankAccount?.toJson(),
    };
  }
}


class BankAccount {
  final String cardHolderName;
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  BankAccount({
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      cardHolderName: json['cardHolderName'] ?? '',
      cardNumber: json['cardNumber'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      cvv: json['cvv'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
    };
  }
}