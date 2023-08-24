import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_handagote/bluetooth_constants.dart';
import 'package:smart_handagote/logic/firebase_helper.dart';
import 'package:collection/collection.dart';
import 'package:smart_handagote/view/components/dialog.dart';

class BleTest extends StatefulWidget {
  const BleTest({Key? key});

  @override
  State<BleTest> createState() => _BleTestState();
}

class _BleTestState extends State<BleTest> {
  FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;
  List<BluetoothDevice> devices = [];
  final TextEditingController controller = TextEditingController();
  BluetoothDevice? device;
  String name = "default";
  String uid = "default";

  @override
  void initState() {
    super.initState();
    fetchDataFromFirebase(); // Firebaseからデータを取得する
    startScan();
  }

  // Firebaseからデータを取得する非同期メソッド
  Future<void> fetchDataFromFirebase() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String name = await FirebaseHelper().getUserName(user.uid);
        setState(() {
          uid = user.uid;
          name = name;
        });
      } else {
        if (!mounted) return;
        DialogHelper.showCustomDialog(
            context: context, title: 'ログインしてください', message: '');
      }
    } catch (e) {
      setState(() {
        uid = "error";
        name = "error";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data from Firebase.')),
      );
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
            final targetService = result.advertisementData.serviceUuids
                .contains(BluetoothConstants.serviceUuid);

            // 対応しているserviceが含まれていれば、デバイス一覧の配列に追加する。
            // TODO: テスト用にコメントアウトしている。
            // 自分の端末のみを対象にするため。
            if (targetService) {
              devices.add(result.device);
            }
          }
        }
      });
    });

    // 以前に接続したことのあるBluetoothを取得する
    flutterBluePlus.connectedDevices.then((value) {
      setState(() {
        for (final result in value) {
          if (!devices.contains(result)) {
            devices.add(result);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    // BLEスキャンを停止し、接続を解除する
    flutterBluePlus.stopScan();
    // if (device != null) {
    //   device!.disconnect();
    // }
    super.dispose();
  }

  // ここに新しい関数を定義します
  Widget buildDeviceItem(BluetoothDevice deviceItem) {
    return ListTile(
      title: Text(deviceItem.name),
      subtitle: StreamBuilder(
        stream: deviceItem.state,
        initialData: BluetoothDeviceState.disconnected,
        builder: (c, snapshot) {
          switch (snapshot.data) {
            case BluetoothDeviceState.connected:
              return const Text('Connected');
            case BluetoothDeviceState.connecting:
              return const Text('Connecting');
            case BluetoothDeviceState.disconnected:
              return const Text('Disconnected');
            case BluetoothDeviceState.disconnecting:
              return const Text('Disconnecting');
            default:
              return const Text('Unknown');
          }
        },
      ),
      onTap: () async {
        // 最新の接続状況を取得して、それに応じて接続処理を行なって画面遷移を行う
        deviceItem.state.first.then((value) async {
          switch (value) {
            case BluetoothDeviceState.connected:
              break;
            case BluetoothDeviceState.connecting:
              break;
            case BluetoothDeviceState.disconnected:
              await deviceItem.connect();
              // BLEの処理を行う
              // UIDと名前をESP32に送信する
              await sendUidAndNameToESP32(deviceItem);
              // BLEを切断する
              await deviceItem.disconnect();
              break;
            case BluetoothDeviceState.disconnecting:
              await deviceItem.connect();
              break;
            default:
              return;
          }
        });
      },
    );
  }

  // BluetoothDeviceにUIDと名前を送信する関数
  Future<void> sendUidAndNameToESP32(BluetoothDevice device) async {
    // クラス内で保持しているUIDと名前を取得
    final uid = this.uid;
    final name = this.name;

    // UIDと名前がnullでない場合に送信処理を行う
    if (uid != null && name != null) {
      // UIDと名前をデータとして連結
      final sendData = '$uid:$name';

      // 送信用のCharacteristicを取得
      final sendCharacteristic =
          await getCharByUuid(BluetoothConstants.sendUidAndNameUuid);

      // 送信用のCharacteristicが取得できた場合にデータを書き込む
      if (sendCharacteristic != null) {
        await writeToCharacteristic(sendCharacteristic, sendData);
      } else {
        if (!mounted) return;
        DialogHelper.showCustomDialog(
            context: context,
            title: 'エラー',
            message: 'Characteristicの取得に失敗しました');
      }
    }
  }

// UUIDに基づいてBluetoothCharacteristicを取得する関数
  Future<BluetoothCharacteristic?> getCharByUuid(String uuid) async {
    // サービスを探索して取得
    final service = await findService();

    // 指定したUUIDに一致するCharacteristicを検索して返す
    return service?.characteristics.firstWhereOrNull((element) {
      return element.uuid.toString() == uuid;
    });
  }

// Bluetoothデバイスからサービスを見つけて返す関数
  Future<BluetoothService?> findService() async {
    try {
      // Bluetoothデバイスからサービスを探索して取得
      final List<BluetoothService> services = await device!.discoverServices();

      // 指定したUUIDに一致するサービスを検索して返す
      return services.firstWhere((service) {
        return service.uuid.toString() == BluetoothConstants.serviceUuid;
      });
    } catch (e) {
      // サービスが見つからない場合にエラーメッセージを出力し、nullを返す
      print('Error finding service: $e');
      return null;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Devices'),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final deviceItem = devices[index];
          return buildDeviceItem(deviceItem);
        },
      ),
    );
  }
}
