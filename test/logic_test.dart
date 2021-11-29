import 'package:flutter_test/flutter_test.dart';
import 'package:teamtrack/functions/Statistics.dart';

void main() {
  test("Large data", () {
    List<double> arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100];
    List<double> arrWithoutOutliers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    expect(arr.median(), 6);
    expect(arr.removeOutliers(true), arrWithoutOutliers);
    expect(arr.q1(), 3);
    expect(arr.q3(), 9);
  });
  test("Small Data", () {
    List<double> arr = [1, 2];
    List<double> arrWithoutOutliers = [1, 2];
    expect(arr.median(), 1.5);
    expect(arr.removeOutliers(true), arrWithoutOutliers);
    expect(arr.q1(), 0);
    expect(arr.q3(), 0);
  });
  test("No Data", () {
    List<double> arr = [];
    List<double> arrWithoutOutliers = [];
    expect(arr.median(), 0);
    expect(arr.removeOutliers(true), arrWithoutOutliers);
    expect(arr.q1(), 0);
    expect(arr.q3(), 0);
  });
}
