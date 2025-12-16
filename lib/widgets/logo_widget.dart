import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 40),
      height: 200,
      child: Image.asset(
        'lib/assets/images/logo/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Si falla la imagen, muestra un icono
          return Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Theme.of(context).primaryColor,
          );
        },
      ),
    );
  }
}
