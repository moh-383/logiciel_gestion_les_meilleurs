import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Gère l'enregistrement du token FCM auprès du serveur et l'affichage
/// des notifications quand l'app est au premier plan (FCM seul n'affiche
/// rien en foreground sur Android : il faut flutter_local_notifications).
class FcmService {
  final Dio dio;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialise = false;

  FcmService({required this.dio});

  Future<void> initialiser() async {
    if (_initialise) return;
    _initialise = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_afficherNotificationLocale);
    FirebaseMessaging.instance.onTokenRefresh.listen(_envoyerToken);
  }

  /// À appeler après un login réussi (ou au démarrage si une session
  /// existe déjà) : récupère et transmet le token courant. Échec
  /// silencieux hors ligne — retenté au prochain `onTokenRefresh`.
  Future<void> enregistrerTokenCourant() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _envoyerToken(token);
    } catch (e) {
      debugPrint('Récupération du token FCM échouée : $e');
    }
  }

  Future<void> effacerToken() async {
    try {
      await dio.patch('/utilisateurs/me/fcm-token', data: {'fcm_token': ''});
    } on DioException catch (_) {
      // Sans conséquence grave si hors ligne à la déconnexion.
    }
  }

  Future<void> _envoyerToken(String token) async {
    try {
      await dio.patch('/utilisateurs/me/fcm-token', data: {'fcm_token': token});
    } on DioException catch (e) {
      debugPrint('Envoi du token FCM échoué : ${e.message}');
    }
  }

  Future<void> _afficherNotificationLocale(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'retards_paiement',
        'Retards de paiement',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }
}

/// Handler top-level obligatoire pour Android : reçoit les messages FCM
/// quand l'app est fermée ou en arrière-plan (Android affiche déjà la
/// notif système par défaut ; réservé pour du futur logging/import).
@pragma('vm:entry-point')
Future<void> gestionnaireArrierePlanFcm(RemoteMessage message) async {}

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(dio: ref.watch(dioProvider)));