import 'package:parkinsondetetion/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:parkinsondetetion/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:parkinsondetetion/ui/views/home/home_view.dart';
import 'package:parkinsondetetion/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:parkinsondetetion/services/authentication_service.dart';
import 'package:parkinsondetetion/ui/views/login/login_view.dart';
import 'package:parkinsondetetion/ui/views/doctor/doctor_view.dart';
import 'package:parkinsondetetion/ui/views/patience/patience_view.dart';
import 'package:parkinsondetetion/services/test_service.dart';
import 'package:parkinsondetetion/services/reports_service.dart';
import 'package:parkinsondetetion/ui/views/camera_test/camera_test_view.dart';
import 'package:parkinsondetetion/ui/views/tap_test/tap_test_view.dart';
import 'package:parkinsondetetion/ui/views/tremor_test/tremor_test_view.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: DoctorView),
    MaterialRoute(page: PatienceView),
    MaterialRoute(page: CameraTestView),
    MaterialRoute(page: TremorTestView),
    MaterialRoute(page: TapTestView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: AuthenticationService),
    LazySingleton(classType: TestService),
    LazySingleton(classType: ReportsService),
// @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}