class History {
  final String date;
  final String time_in;
  final String time_out;
  final String total;

  History({this.date, this.time_in, this.time_out, this.total});

  factory History.fromJson(Map<String, dynamic> parsedJson) {
    return History(
      date: parsedJson['date'] as String,
      time_in: parsedJson['time_in'] as String,
      time_out: parsedJson['time_out'] as String,
      total: parsedJson['total'] as String,
    );
  }
}