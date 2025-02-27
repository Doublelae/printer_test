import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:za_blue_printer/models/blue_device.dart';
import 'package:za_blue_printer/models/connection_status.dart';
import 'package:za_blue_printer/receipt/receipt_section_text.dart';
import 'package:za_blue_printer/receipt/receipt_text_enum.dart';
import 'package:za_blue_printer/za_blue_printer.dart';

void main() {
  runApp(const MyApp());
}

Future<String> networkImageToBase64(String imageUrl) async {
  http.Response response = await http.get(Uri.parse(imageUrl));
  final bytes = response.bodyBytes;

  debugPrint('converted image =>>> ${base64Encode(bytes)}');
  return base64Encode(bytes);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ZaBluePrinter _bluePrintPos = ZaBluePrinter.instance;
  List<BlueDevice> _blueDevices = <BlueDevice>[];
  BlueDevice? _selectedDevice;
  bool _isLoading = false;
  int _loadingAtIndex = -1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Blue Print Pos'),
        ),
        body:
         SafeArea(
          child: _isLoading && _blueDevices.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : _blueDevices.isNotEmpty
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                              
                          Column(
                            children: List<Widget>.generate(_blueDevices.length, (int index) {
                              return Row(
                                children: <Widget>[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _blueDevices[index].address == (_selectedDevice?.address ?? '')
                                          ? _onDisconnectDevice
                                          : () => _onSelectDevice(index),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              _blueDevices[index].name,
                                              style: TextStyle(
                                                color: _selectedDevice?.address == _blueDevices[index].address ? Colors.blue : Colors.black,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _blueDevices[index].address,
                                              style: TextStyle(
                                                color:
                                                    _selectedDevice?.address == _blueDevices[index].address ? Colors.blueGrey : Colors.grey,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_loadingAtIndex == index && _isLoading)
                                    Container(
                                      height: 24.0,
                                      width: 24.0,
                                      margin: const EdgeInsets.only(right: 8.0),
                                      child: const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ),
                                      ),
                                    ),
                                  if (!_isLoading && _blueDevices[index].address == (_selectedDevice?.address ?? ''))
                                    TextButton(
                                      onPressed: _onPrintReceipt,
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(MaterialState.pressed)) {
                                              return Theme.of(context).colorScheme.primary.withOpacity(0.5);
                                            }
                                            return Theme.of(context).primaryColor;
                                          },
                                        ),
                                      ),
                                      child: Container(
                                        color: _selectedDevice == null ? Colors.grey : Colors.blue,
                                        padding: const EdgeInsets.all(8.0),
                                        child: const Text(
                                          'Test Print',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    )
                  :  Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Scan bluetooth device',
                            style: TextStyle(fontSize: 24, color: Colors.blue),
                          ),
                          Text(
                            'Press button scan',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          TextButton(
                                      onPressed: _onPrintReceipt,
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(MaterialState.pressed)) {
                                              return Theme.of(context).colorScheme.primary.withOpacity(0.5);
                                            }
                                            return Theme.of(context).primaryColor;
                                          },
                                        ),
                                      ),
                                      child: Container(
                                        color: _selectedDevice == null ? Colors.grey : Colors.blue,
                                        padding: const EdgeInsets.all(8.0),
                                        child: const Text(
                                          'Test Print',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    )
                        ],
                      ),
                    ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isLoading ? null : _onScanPressed,
          backgroundColor: _isLoading ? Colors.grey : Colors.blue,
          child: const Icon(Icons.search),
        ),
      ),
    );
  }

  Future<void> _onScanPressed() async {
    setState(() => _isLoading = true);
    _bluePrintPos.scan().then((List<BlueDevice> devices) {
      if (devices.isNotEmpty) {
        setState(() {
          _blueDevices = devices;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  void _onDisconnectDevice() {
    _bluePrintPos.disconnect().then((ConnectionStatus status) {
      if (status == ConnectionStatus.disconnected) {
        setState(() {
          _selectedDevice = null;
        });
      }
    });
  }

  void _onSelectDevice(int index) {
    setState(() {
      _isLoading = true;
      _loadingAtIndex = index;
    });
    final BlueDevice blueDevice = _blueDevices[index];
    _bluePrintPos.connect(blueDevice).then((ConnectionStatus status) {
      if (status == ConnectionStatus.connected) {
        setState(() => _selectedDevice = blueDevice);
      } else if (status == ConnectionStatus.timeout) {
        _onDisconnectDevice();
      } else {
        print('$runtimeType - something wrong');
      }
      setState(() => _isLoading = false);
    });
  }

  Future<void> _onPrintReceipt() async {
    
    /// Example for Print Image
    final ByteData logoBytes = await rootBundle.load(
      'assets/logo.jpg',
    );

    String base =
        "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";

    /// Example for Print Text
    final ReceiptSectionText receiptText = ReceiptSectionText();

    receiptText.addText(text: 'မြန်မာလို', is80: false, alignment: ReceiptAlignment.center, size: ReceiptTextSize.large);

    receiptText.addText(text: 'သစ်ရွက်', is80: false, alignment: ReceiptAlignment.center, size: ReceiptTextSize.large);
    receiptText.addImage(base);
    receiptText.addTableHeader(firstColHeader: "firstColHeader", secondColHeader: "secondColHeader", thirdColHeader: "thirdColHeader", fourthColHeader: "fourthColHeader");
receiptText.add1Col1CellTableRow(value: "value", totalPrice: "totalPrice");
receiptText.add2Col1CellTableRow(firstValue: "firstValue", secondValue: "secondValue", totalPrice: "totalPrice");
receiptText.addTitleCustomeText(text: "text", is80: false, alignment: ReceiptAlignment.center, size: ReceiptTextSize.doubleextralarge);
  final info = NetworkInfo();
  final wifiIP = await info.getWifiIP();
  log("wifiIP ==> $wifiIP");
  try{
  final result =  await ZaBluePrinter().printReceiptTextA4A5Wireless(
      receiptText,
      isA4: true,     
      host: wifiIP .toString()??'',byteLog: false
    );
    log("printer result ==> $result??");
    }catch(e){
      log("printer error ===> $e");
    }
    // // receiptSecondText.addSpacer();
    // await _bluePrintPos.printReceiptText(receiptText, is80: false);
  }
}
