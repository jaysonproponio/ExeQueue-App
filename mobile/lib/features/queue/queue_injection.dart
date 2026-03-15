import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:exequeue_mobile/features/queue/data/datasources/queue_local_data_source.dart';
import 'package:exequeue_mobile/features/queue/data/datasources/queue_notification_data_source.dart';
import 'package:exequeue_mobile/features/queue/data/datasources/queue_remote_data_source.dart';
import 'package:exequeue_mobile/features/queue/data/repositories/queue_repository_impl.dart';
import 'package:exequeue_mobile/features/queue/domain/repositories/queue_repository.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/get_live_board.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/get_queue_status.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/initialize_notifications.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/join_queue_from_qr.dart';
import 'package:exequeue_mobile/features/queue/domain/usecases/subscribe_to_queue_topic.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/join_queue_cubit.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/live_board_cubit.dart';
import 'package:exequeue_mobile/features/queue/presentation/cubit/queue_status_cubit.dart';

void registerQueueFeature(GetIt sl) {
  sl.registerLazySingleton<http.Client>(http.Client.new);

  sl.registerLazySingleton<QueueRemoteDataSource>(
    () => QueueRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  sl.registerLazySingleton<QueueLocalDataSource>(QueueLocalDataSourceImpl.new);
  sl.registerLazySingleton<QueueNotificationDataSource>(
    () => QueueNotificationDataSourceImpl(),
  );

  sl.registerLazySingleton<QueueRepository>(
    () => QueueRepositoryImpl(
      remoteDataSource: sl<QueueRemoteDataSource>(),
      localDataSource: sl<QueueLocalDataSource>(),
      notificationDataSource: sl<QueueNotificationDataSource>(),
    ),
  );

  sl.registerLazySingleton<GetQueueStatus>(
    () => GetQueueStatus(sl<QueueRepository>()),
  );
  sl.registerLazySingleton<GetLiveBoard>(
    () => GetLiveBoard(sl<QueueRepository>()),
  );
  sl.registerLazySingleton<JoinQueueFromQr>(
    () => JoinQueueFromQr(sl<QueueRepository>()),
  );
  sl.registerLazySingleton<InitializeNotifications>(
    () => InitializeNotifications(sl<QueueRepository>()),
  );
  sl.registerLazySingleton<SubscribeToQueueTopic>(
    () => SubscribeToQueueTopic(sl<QueueRepository>()),
  );

  sl.registerFactory<QueueStatusCubit>(
    () => QueueStatusCubit(getQueueStatus: sl<GetQueueStatus>()),
  );
  sl.registerFactory<LiveBoardCubit>(
    () => LiveBoardCubit(getLiveBoard: sl<GetLiveBoard>()),
  );
  sl.registerFactory<JoinQueueCubit>(
    () => JoinQueueCubit(
      joinQueueFromQr: sl<JoinQueueFromQr>(),
      subscribeToQueueTopic: sl<SubscribeToQueueTopic>(),
    ),
  );
}
