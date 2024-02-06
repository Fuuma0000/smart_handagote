import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_handagote/bluetooth_constants.dart';
import 'package:smart_handagote/constant.dart';
import 'package:smart_handagote/logic/firebase_helper.dart';
import 'package:collection/collection.dart';
import 'package:smart_handagote/view/components/alert_dialog.dart';

class AddFingerprintPage extends StatefulWidget {
  const AddFingerprintPage({super.key});

  @override
  State<AddFingerprintPage> createState() => _AddFingerprintPageState();
}

class _AddFingerprintPageState extends State<AddFingerprintPage> {
  FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;
  List<BluetoothDevice> devices = [];
  List<String> settedUUID = [];
  Map<String, String> fetchDevices = {};
  final TextEditingController controller = TextEditingController();
  BluetoothDevice? device;
  String _name = '';
  String _uid = '';

  bool isLoading = false; // ロード中かどうかを表す状態変数

  @override
  void initState() {
    super.initState();
    Future(() async {
      fetchDevicename(); // Firebaseからデータを取得する
    });
    Future(() async {
      fetchDataFromFirebase(); // Firebaseからデバイス名を取得する
    });
    startScan();
  }

  // firebaseからデバイス名を取得する非同期メソッド
  Future<void> fetchDevicename() async {
    try {
      Map<String, String> fetchedDevices =
          await FirebaseHelper().getAllDevices();
      setState(() {
        fetchDevices = fetchedDevices;
        print(fetchedDevices);
      });
    } catch (e) {
      print('Error fetching device names from Firebase: $e');
    }
  }

// Firebaseからデータを取得する非同期メソッド
  Future<void> fetchDataFromFirebase() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String name = await FirebaseHelper().getUserName(user.uid);
        setState(() {
          _uid = user.uid;
          _name = name;
        });
      } else {
        // if (!mounted) return;
        // DialogHelper.showCustomDialog(
        //     context: context, title: 'ログインしてください', message: '');
      }
    } catch (e) {
      setState(() {
        _uid = "error";
        _name = "error";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data from Firebase.')),
      );
    } finally {
      // ロードが完了したので isLoading を false に設定
      setState(() {
        isLoading = false;
      });
    }
  }

  // Bluetoothデバイスからサービスを見つけて返す関数
  Future<BluetoothService?> findService(device) async {
    try {
      final List<BluetoothService> services = await device.discoverServices();
      // Bluetoothデバイスからサービスを探索して取得
      for (final uuid in BluetoothConstants.serviceUuids) {
        // 指定したUUIDに一致するサービスを検索して返す
        final matchingService = services.firstWhereOrNull(
          (service) => service.uuid.toString() == uuid,
        );

        if (matchingService != null) {
          return matchingService;
        }
      }

      return null; // どのUUIDにも一致しなかった場合
    } catch (e) {
      // サービスが見つからない場合にエラーメッセージを出力し、nullを返す
      print('Error finding service: $e');
      return null;
    }
  }

  startScan() {
    devices = [];

    // Bluetoothデバイスをスキャンする
    flutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    // スキャンした結果を受け取る
    flutterBluePlus.scanResults.listen((results) {
      setState(() {
        for (ScanResult result in results) {
          if (!devices.contains(result.device)) {
            // 対応しているserviceが含まれているのかを確認する
            for (final uuid in BluetoothConstants.serviceUuids) {
              final targetService =
                  result.advertisementData.serviceUuids.contains(uuid);
              // 対応しているserviceが含まれていれば、デバイス一覧の配列に追加する。
              // 自分の端末のみを対象にするため。
              if (targetService) {
                devices.add(result.device);
                settedUUID.add(uuid);
              }
            }
          }
        }
      });
    });

    // 以前に接続したことのあるBluetoothを取得する
    // flutterBluePlus.connectedDevices.then((value) {
    //   setState(() {
    //     for (final result in value) {
    //       if (!devices.contains(result)) {
    //         devices.add(result);
    //       }
    //     }
    //   });
    // });
  }

  @override
  void dispose() {
    // BLEスキャンを停止し、接続を解除する
    flutterBluePlus.stopScan();
    if (device != null) {
      device!.disconnect();
    }
    super.dispose();
  }

  // TODO: 適当にやったの。1の時は真ん中に表示されるの
  Widget _addFingerprintWidget() {
    return Column(
      children: List.generate(devices.length, (index) {
        final device = devices[index];
        final deviceName = fetchDevices[settedUUID[index]] ?? 'Unknown Device';
        if (devices.length == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _addBtnWidget(deviceName, () {
                  connectToDeviceAndSendData(device);
                }),
              ],
            ),
          );
        } else if (devices.length >= 2) {
          if (index % 2 == 0) {
            final nextIndex = index + 1;
            final nextDevice =
                devices.length > nextIndex ? devices[nextIndex] : null;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _addBtnWidget('No.${index + 1}', () {
                    connectToDeviceAndSendData(device);
                  }),
                  if (nextDevice != null)
                    _addBtnWidget('No.${nextIndex + 1}', () {
                      connectToDeviceAndSendData(nextDevice);
                    }),
                ],
              ),
            );
          }
        }
        return const SizedBox(height: 0);
      }),
    );
  }

// デバイスに接続しデータを送信するメソッド
  void connectToDeviceAndSendData(BluetoothDevice device) async {
    try {
      await device.connect();
      await sendUidAndNameToESP32(device);
      await device.disconnect();
      if (!mounted) return;
      AlertDialogHelper.showCustomDialog(
          context: context,
          title: '完了',
          message: 'ユーザ情報を送信しました',
          onPressed: () {
            Navigator.pop(context);
          });
    } catch (e) {
      if (!mounted) return;
      AlertDialogHelper.showCustomDialog(
          context: context,
          title: 'エラー',
          message: '送信に失敗しました',
          onPressed: () {
            Navigator.pop(context);
          });
    }
  }

  // BluetoothDeviceにUIDと名前を送信する関数
  Future<void> sendUidAndNameToESP32(BluetoothDevice device) async {
    // UIDと名前をデータとして連結
    final sendData = '$_uid:$_name';
    // 送信用のCharacteristicを取得
    final sendCharacteristic =
        await getCharByUuid(BluetoothConstants.sendUidAndNameUuid, device);
    // 送信用のCharacteristicが取得できた場合にデータを書き込む
    if (sendCharacteristic != null) {
      await writeToCharacteristic(sendCharacteristic, sendData);
    } else {
      // if (!mounted) return;
      // DialogHelper.showCustomDialog(
      //     context: context, title: 'エラー', message: 'Characteristicの取得に失敗しました');
    }
  }

  // UUIDに基づいてBluetoothCharacteristicを取得する関数
  Future<BluetoothCharacteristic?> getCharByUuid(
      String uuid, BluetoothDevice device) async {
    // サービスを探索して取得
    final service = await findService(device);
    // 指定したUUIDに一致するCharacteristicを検索して返す
    return service?.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString() == uuid;
    });
  }

// BluetoothCharacteristicにデータを書き込む関数
  Future<void> writeToCharacteristic(
      BluetoothCharacteristic characteristic, String value) async {
    // 文字列をバイトデータに変換して書き込むためのリストを作成
    List<int> codeUnits = [];
    for (int i = 0; i < value.length; i++) {
      codeUnits.add(value.codeUnitAt(i));
    }

    // バイトデータをCharacteristicに書き込む
    await characteristic.write(codeUnits);
  }

  Widget _addBtnWidget(String deviceName, GestureTapCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Constant.darkGray,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(deviceName,
                style: const TextStyle(
                    color: Constant.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Icon(Icons.fingerprint, size: 40, color: Constant.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('指紋登録'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.secondary,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _addFingerprintWidget(),
    );
  }
}
