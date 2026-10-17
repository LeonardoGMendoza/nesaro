import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/automation_repository.dart';
import 'data/repositories/execution_repository.dart';
import 'data/services/nesaro_api.dart';
// Gerado pelo comando `flutterfire configure` (veja o README).
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // Composition root do app: tudo é criado AQUI e entregue às telas por injeção.
    // Nenhuma tela chama FirebaseAuth.instance, FirebaseFirestore.instance ou http direto.
    MultiProvider(
      providers: [
        // 1) Dependências externas
        Provider<FirebaseAuth>.value(value: FirebaseAuth.instance),
        Provider<FirebaseFirestore>.value(value: FirebaseFirestore.instance),

        // 2) Repositórios e serviços (cada um recebe só o que precisa)
        Provider<AuthRepository>(
          create: (c) => AuthRepository(
            auth: c.read<FirebaseAuth>(),
            firestore: c.read<FirebaseFirestore>(),
          ),
        ),
        Provider<NesaroApi>(
          create: (c) => NesaroApi(
            client: http.Client(),
            idTokenProvider: c.read<AuthRepository>().idToken,
            baseUrl: AppConfig.apiBaseUrl,
          ),
          dispose: (_, api) => api.close(),
        ),
        Provider<AutomationRepository>(
          create: (c) => AutomationRepository(firestore: c.read<FirebaseFirestore>()),
        ),
        Provider<ExecutionRepository>(
          create: (c) => ExecutionRepository(firestore: c.read<FirebaseFirestore>()),
        ),
        Provider<AccountRepository>(
          create: (c) => AccountRepository(
            firestore: c.read<FirebaseFirestore>(),
            api: c.read<NesaroApi>(),
          ),
        ),
      ],
      child: const NesaroApp(),
    ),
  );
}
