import 'package:flutter_test/flutter_test.dart';
import 'package:equations/equations.dart';
List<double> solutions=[0.0];
void main() {
  test("OPR6m4t", () {
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 1.0],
      [1.0, 0.0, 1.0, 0.0],
      [0.0, 1.0, 0.0, 1.0],
      [0.0, 1.0, 1.0, 0.0],
      [1.0, 0.0, 0.0, 1.0]
    ];
    List<List<double>> matchResults = [
      [1.0],
      [11.0],
      [2.0],
      [0.0],
      [14.0],
      [2.0]
    ];
    calculator(matchSchedule, matchResults, 6,4);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), -2);
  });
  test("OPR10m8t", () {
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0],
      [1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0],
      [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0],
      [1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0],
      [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0],
      [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0],
      [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0]
    ];
    List<List<double>> matchResults = [
      [1.0],
      [11.0],
      [2.0],
      [0.0],
      [14.0],
      [2.0],
      [14.0],
      [21.0],
      [14.0],
      [21.0]
    ];
    calculator(matchSchedule, matchResults,10,8);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), 27);
  });
  test("OPR5m4t", () {
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0],
      [1.0, 0.0, 1.0, 0.0],
      [0.0, 1.0, 1.0, 0.0],
      [1.0, 0.0, 0.0, 1.0],
      [0.0, 1.0, 0.0, 1.0]
    ];
    List<List<double>> matchResults = [
      [10.0],
      [13.0],
      [7.0],
      [15.0],
      [10.0]
    ];
    calculator(matchSchedule, matchResults,5,4);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), 8);
  });
  test("OPR3m4t", () {
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 1.0],
      [1.0, 0.0, 1.0, 0.0]
    ];
    List<List<double>> matchResults = [
      [1.0],
      [11.0],
      [2.0]
    ];
    calculator(matchSchedule, matchResults, 3,4);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), double.infinity);
  });
}
void calculator(List<List<double>> a, List<List<double>> b, int rows, int cols){
  /*
   * input: matches, results, rows: # of matches, cols: number of teams
   * m1: teams in matches
   * m2: match results
   * m3: transposed m1
   * m4: m3*m1 (opr system)
   * m5: m3*m2 (opr results)
   */
  Matrix<double> m1 = RealMatrix.fromData(
      columns: cols,
      rows: rows,
      data: a
  );

  Matrix<double> m2 = RealMatrix.fromData(
      columns: 1,
      rows: m1.rowCount,
      data: b
  );

  Matrix<double> m3 = m1.transpose();


  Matrix<double> m4 = m3*m1;
  Matrix<double> m5 = m3*m2;

  //LUSolver formula to solve system of equations

  final lu = LUSolver(
      equations: m4.toListOfList(),
      constants: m5.toList()
  );
  solutions = lu.solve();

  //printer statements for backend view

    for(int i=0;i<solutions.length;++i){
      double opr = solutions.elementAt(i);
      String printout = "Team "+(i+1).toString()+" = "+opr.toString();
      print(printout);
    }
  print("");
    // Output: prints of opr calculations (no rounding) and updated solutions
}