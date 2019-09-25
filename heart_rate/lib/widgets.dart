// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_blue/flutter_blue.dart';
import 'package:vibrate/vibrate.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('SELECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                    result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({Key key, this.service, this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0) {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Service'),
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                style: Theme.of(context)
                    .textTheme
                    .body1
                    .copyWith(color: Theme.of(context).textTheme.caption.color))
          ],
        ),
        children: characteristicTiles,
      );
    } else {
      return ListTile(
        title: Text('Service'),
        subtitle:
            Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;

  const CharacteristicTile(
      {Key key,
      this.characteristic,
      this.descriptorTiles,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        return ExpansionTile(
          title: ListTile(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Characteristic'),
                Text(
                    '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
                    style: Theme.of(context).textTheme.body1.copyWith(
                        color: Theme.of(context).textTheme.caption.color))
              ],
            ),
            subtitle: Text(value.toString()),
            contentPadding: EdgeInsets.all(0.0),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.file_download,
                  color: Theme.of(context).iconTheme.color.withOpacity(0.5),
                ),
                onPressed: onReadPressed,
              ),
              IconButton(
                icon: Icon(Icons.file_upload,
                    color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
                onPressed: onWritePressed,
              ),
              IconButton(
                icon: Icon(
                    characteristic.isNotifying
                        ? Icons.sync_disabled
                        : Icons.sync,
                    color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
                onPressed: onNotificationPressed,
              )
            ],
          ),
          children: descriptorTiles,
        );
      },
    );
  }
}

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;

  const DescriptorTile(
      {Key key, this.descriptor, this.onReadPressed, this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Descriptor'),
          Text('0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
              style: Theme.of(context)
                  .textTheme
                  .body1
                  .copyWith(color: Theme.of(context).textTheme.caption.color))
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
        stream: descriptor.value,
        initialData: descriptor.lastValue,
        builder: (c, snapshot) => Text(snapshot.data.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5),
            ),
            onPressed: onWritePressed,
          )
        ],
      ),
    );
  }
}

class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key key, @required this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final maxHeartRateController = TextEditingController();

  static const String HR_CHAR_UUID = "2A37";

  int _heartRate = 0;
  int _maxHeartRate = 0;

  List<int> sessionHeartRates = [];
  List<DateTime> sessionHeartRateTimes = [];

  BluetoothDevice device;
  BluetoothDeviceState s;
  BluetoothCharacteristic hrChar;
  Stream<List<int>> rateStream;

  var _trackingStarted = '';

  var trackingStatus = false;
  var canShowAlert = true;  //So we don't show a dialog immediately after closing one
  var canVibe = false;

  @override
  void dispose(){
    maxHeartRateController.dispose();
    super.dispose();
  }

  void _setMaxHeartRate(){
    setState(() {
      canShowAlert = true;
      int toSet = int.tryParse(maxHeartRateController.text) ?? 0; //parse, set to 0 if error
      _maxHeartRate = toSet;
    });
  }

  void _logHeartRate(){
    setState(() {
      if(_heartRate != 0) {

        sessionHeartRates.add(_heartRate);

        DateTime time = DateTime.now();

        if(sessionHeartRateTimes.length == 0){
          String seconds = time.second.toString();
          if (seconds.length == 1) {
            seconds = '0' + seconds;
          }

          String minutes = time.minute.toString();
          if (minutes.length == 1) {
            minutes = '0' + minutes;
          }

          _trackingStarted = time.hour.toString() + ':' + minutes + ':' +
              seconds;
        }

        sessionHeartRateTimes.add(time);
      }
      Future.delayed(const Duration(seconds: 10), (){
        if(trackingStatus && this.mounted){
          _logHeartRate();
        }
      });
    });

  }

  void _trackingResetButton(){
    setState(() {
      sessionHeartRates = [];
      sessionHeartRateTimes = [];

      _logHeartRate();
    });
  }

  void _setStreams() {
    device.state.listen((state){
      s = state;
      if(s == BluetoothDeviceState.connected && this.mounted) {
        setState(() {
          device = widget.device;

          if (!trackingStatus) { //Once the
            print('Starting log(from setStreams())');
            trackingStatus = true;
            _logHeartRate();
          }
        });

        device.discoverServices().asStream().listen((services) {

          var hasHRService = false;

          services.forEach((serv) {
            serv.characteristics.forEach((c) {
              if (c.uuid.toString().toUpperCase().contains(HR_CHAR_UUID)) {

                hasHRService = true;

                hrChar = c;
                hrChar.setNotifyValue(true);
                rateStream = hrChar.value;
                rateStream.listen((vals) {
                  if (this.mounted) {
                    setState(() {
                      if (vals.length > 0) {
                        _heartRate = vals[1];
                      }

                      if(_maxHeartRate != 0 && _heartRate > _maxHeartRate && canShowAlert){
                        _showOverMaxDialog();
                      }

                    });
                  }
                });
              }
            });
          });

          if(!hasHRService){
            showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('No heart rate service detected'),
                  content: const Text('Please go back and select a different bluetooth device'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Ok'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }

        });
      } else {
        trackingStatus = false;
      }
    });
  }

  void _showOverMaxDialog() {

    canShowAlert = false;

    if(canVibe){
      Vibrate.vibrate();
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('You have exceeded your max heart rate!'),
          content: const Text('This alert will not show for another minute'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).whenComplete((){
      Future.delayed(const Duration(minutes: 1), (){
        if(trackingStatus && this.mounted){
          canShowAlert = true;
        }
      });
    });
  }

  _getCanVibrate() async {
    Vibrate.canVibrate.then((can){
      canVibe = can;
    });
  }

  @override
  void initState() {
    super.initState();
    _getCanVibrate();
  }

  Border _getBorder(){

    BorderSide side = new BorderSide(
      width: 2.0,
      color: Colors.grey,
    );

    return new Border(
      right: side,
      left: side,
      top: side,
      bottom: side,
    );
  }

  @override
  Widget build(BuildContext context) {

    if(device == null && this.mounted){
      device = widget.device;
      _setStreams();
    }

    return Container (
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 5),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Your current heartrate is:',
                  style: Theme.of(context).textTheme.display1,
                ),
                Text(
                  '$_heartRate',
                  style: Theme.of(context).textTheme.display2,

                ),

              ],
            ),
          ),

          Container(
            decoration: new BoxDecoration(
                border: _getBorder()
            ),
            margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Maximum Heart Rate:',
                  style: Theme.of(context).textTheme.headline,
                ),
                Text(
                  '$_maxHeartRate',
                  style: Theme.of(context).textTheme.title,
                ),
                Text(
                  'Enter a maximum heart rate:',
                  style: Theme.of(context).textTheme.headline,
                ),
                Text(
                  '(0 = no max)',
                  style: Theme.of(context).textTheme.subhead,
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    controller: maxHeartRateController,
                    keyboardType: TextInputType.number,
                    onEditingComplete: _setMaxHeartRate,
                  ),
                ),
                RaisedButton(
                  child: Text('Set'),
                  onPressed: _setMaxHeartRate,
                ),
              ],
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Tracking Status: $trackingStatus',
                style: Theme.of(context).textTheme.headline,
              ),
              Text(
                'Tracking since: ' + _trackingStarted,
                style: Theme.of(context).textTheme.headline,
              ),
              RaisedButton(
                child: Text('Reset'),
                onPressed: _trackingResetButton,
              ),
            ],
          ),
          RaisedButton(
            onPressed: (){
              if(trackingStatus){
                Navigator.push(context, MaterialPageRoute(builder: (context) => HeartRateHistory(rates: sessionHeartRates, times: sessionHeartRateTimes,)));
              } else {
                Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text('No history to show')
                ));
              }
            },
            child: Text('View History'),
          )
        ],
      ),
    );
  }
}

class HeartRateHistory extends StatefulWidget {
  HeartRateHistory({Key key, this.title, this.rates, this.times}) : super(key: key);

  final String title;
  final List<int> rates;
  final List<DateTime> times;

  @override
  _HeartRateHistoryState createState() => _HeartRateHistoryState();
}

class _HeartRateHistoryState extends State<HeartRateHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heart Rate History'),
      ),

      body: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: HeartRateGraph(
          seriesList: _getFormattedList(),
        ),

      )
    );
  }

  List<charts.Series<RateObject, DateTime>> _getFormattedList(){
    final List<RateObject> data = [];

    for(int i = 0; i < widget.rates.length; i++){
      data.add(new RateObject(widget.rates[i], widget.times[i]));
    }

    return [
      new charts.Series<RateObject, DateTime>(
        id: 'Rate',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (RateObject rate, _) => rate.time,
        measureFn: (RateObject rate, _) => rate.rate,
        data: data,
      )
    ];
  }
}

class HeartRateGraph extends StatelessWidget {
  HeartRateGraph({Key key, this.seriesList});

  final List<charts.Series> seriesList;


  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(seriesList,
      animate: true,
      domainAxis: new charts.EndPointsTimeAxisSpec(),
      primaryMeasureAxis: new charts.NumericAxisSpec(),

    );
  }
}

class RateObject {
  final int rate;
  final DateTime time;

  RateObject(this.rate, this.time);

}
