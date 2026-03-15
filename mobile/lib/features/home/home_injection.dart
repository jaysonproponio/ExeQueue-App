import 'package:get_it/get_it.dart';

import 'package:exequeue_mobile/features/home/presentation/cubit/home_shell_cubit.dart';

void registerHomeFeature(GetIt sl) {
  sl.registerFactory<HomeShellCubit>(HomeShellCubit.new);
}
