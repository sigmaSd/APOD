import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show jsonDecode;
import 'package:intl/intl.dart' show DateFormat;
import 'dart:io' show Platform;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyApp createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  late Future<Widget> nasa;

  @override
  void initState() {
    super.initState();
    nasa = fetchNasa(date: DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Startup Name Generator',
        home: Scaffold(
          appBar: AppBar(
            title: Text("Nasa"),
          ),
          body: Center(
            child: buildBody(nasa),
          ),
          drawer: Drawer(
              child: ListView(
            children: [
              DrawerHeader(
                child: Icon(Icons.ac_unit_outlined, size: 42),
                decoration: BoxDecoration(
                  color: Colors.red,
                ),
              ),
              Divider(),
              Builder(builder: (context) => pickDate(context)),
              Divider(),
              Builder(builder: (context) => rangeImages(context)),
              Divider(),
              Builder(builder: (context) => randomImages(context)),
            ],
          )),
        ),
        theme: ThemeData(primaryColor: Colors.red));
  }

  FutureBuilder<Widget> buildBody(nasa) {
    return FutureBuilder(
        future: nasa,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          // By default, show a loading spinner.
          return Center(child: CircularProgressIndicator());
        });
  }

  Future<Widget> fetchNasa({date, count, startDate, endDate}) async {
    if (date == null &&
        count == null &&
        startDate == null &&
        endDate == null &&
        startDate == null &&
        endDate == null) {
      throw Exception;
    }

    final apiKey = Platform.environment['NASA_API_KEY'];
    final authority = "api.nasa.gov";
    final path = "/planetary/apod";

    if (date != null) {
      final formatedDate = formatDate(date);
      final response = await http.get(Uri.https(
          authority, path, {"api_key": apiKey, "date": formatedDate}));
      if (response.statusCode == 200) {
        final nasa = Nasa.fromJson(jsonDecode(response.body));
        return Image.network(nasa.hdurl);
      }
    } else if (count != null) {
      final response = await http.get(
          Uri.https(authority, path, {"api_key": apiKey, "count": "$count"}));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final nasa = fromJsonVec(json);

        final grid = GridView.count(
          crossAxisCount: count ~/ 2,
          children: nasa.map((item) => Image.network(item.hdurl)).toList(),
        );
        return grid;
      }
    } else if (startDate != null || endDate != null) {
      final response = await http.get(Uri.https(authority, path, {
        "api_key": apiKey,
        if (startDate != null) "start_date": "${formatDate(startDate)}",
        if (endDate != null) "end_date": "${formatDate(endDate)}"
      }));
      print(response.body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final len = json.length;
        final nasa = fromJsonVec(json);

        final grid = GridView.count(
          crossAxisCount: len ~/ 2,
          children: nasa.map((item) => Image.network(item.hdurl)).toList(),
        );
        return grid;
      }
    }
    return Text("No image in date");
  }

  MaterialButton rangeImages(context) {
    return MaterialButton(
        child: Text(
          "Range Images",
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async {
          final dateRange = await showDateRangePicker(
              context: context,
              firstDate: DateTime(1950),
              lastDate: DateTime.now());
          if (dateRange == null) {
            Navigator.pop(context);
            return;
          }

          final nasa =
              fetchNasa(startDate: dateRange.start, endDate: dateRange.end);

          Navigator.push(context, MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return Scaffold(
                  appBar: AppBar(title: Text('Range Images')),
                  body: buildBody(nasa));
            },
          ));
        });
  }

  MaterialButton randomImages(context) {
    return MaterialButton(
        child: Text(
          "Random Images",
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async {
          var nasa;
          await showDialog(
              context: context,
              builder: (BuildContext context) {
                final textcontroller = TextEditingController();
                return SimpleDialog(
                    title: Text("Enter image count"),
                    children: [
                      TextField(
                          controller: textcontroller,
                          keyboardType: TextInputType.number),
                      MaterialButton(
                          child: Text("Ok"),
                          color: Colors.blue,
                          onPressed: () {
                            Navigator.pop(context);
                            nasa = fetchNasa(
                                count: int.parse(textcontroller.text));
                          })
                    ]);
              });
          if (nasa == null) {
            Navigator.pop(context);
            return;
          }
          Navigator.push(context, MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return Scaffold(
                  appBar: AppBar(title: Text('Random Images')),
                  body: buildBody(nasa));
            },
          ));
        });
  }

  MaterialButton pickDate(context) {
    return MaterialButton(
        child: Text(
          "Pick date",
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(200),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              nasa = fetchNasa(date: date);
            });
          }
          Navigator.pop(context);
        });
  }
}

class Nasa {
  final String hdurl;

  Nasa({required this.hdurl});

  factory Nasa.fromJson(Map<String, dynamic> json) {
    return Nasa(
      hdurl: json['hdurl'],
    );
  }
}

List<Nasa> fromJsonVec(List<dynamic> json) {
  final List<Nasa> nasavec = [];
  for (final item in json) {
    if (item['hdurl'] == null) {
      continue;
    }
    nasavec.add(Nasa(hdurl: item['hdurl']));
  }
  return nasavec;
}

String formatDate(DateTime date) {
  return DateFormat("yyyy-MM-dd").format(date);
}
