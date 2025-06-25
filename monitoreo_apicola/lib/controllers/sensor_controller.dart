import '../models/sensor_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SensorController {
  Future<Sensor?> getSensorDesdeThingSpeak() async {
    final url = Uri.parse(
      "https://api.thingspeak.com/channels/{CHANNEL_ID}/feeds.json?api_key={READ_API_KEY}&results=1",
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final feed = data['feeds'][0];
      return Sensor(
        co2: double.parse(feed['field1']),
        sonido: double.parse(feed['field2']),
        fecha: DateTime.parse(feed['created_at']),
      );
    }
    return null;
  }
}
