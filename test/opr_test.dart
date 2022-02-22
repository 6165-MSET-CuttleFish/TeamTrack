import 'package:flutter_test/flutter_test.dart';
import 'package:equations/equations.dart';

/* Background:
 *  1.0 - team is playing
 *  0.0 - team is not playing
 */

List<double> solutions=[0.0];
void main() {
  test("OPR6m4t", () {
    print("Test 1: 4 teams, 6 matches");
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 1.0],
      [1.0, 0.0, 1.0, 0.0],
      [0.0, 1.0, 0.0, 1.0],
      [0.0, 1.0, 1.0, 0.0],
      [1.0, 0.0, 0.0, 1.0]
    ];
    List<double> matchResults = [
      1.0,
      11.0,
      2.0,
      0.0,
      14.0,
      2.0
    ];
    calculator(matchSchedule, matchResults, 6,4);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), -2);
  });
  test("Some Teams Have Not Played Yet", () {
    print("Test 1: 4 teams, 6 matches");
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 1.0, 0.0],
      [1.0, 0.0, 1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 1.0, 0.0],
      [0.0, 1.0, 1.0, 0.0, 0.0],
      [0.0, 0.0, 0.0, 1.0, 1.0]
    ];
    List<double> matchResults = [
      1.0,
      11.0,
      2.0,
      0.0,
      14.0,
      2.0
    ];
    calculator(matchSchedule, matchResults, 6,5);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), -2);
  });
  test("OPR10m8t", () {
    print("Test 2: 8 teams, 10 matches");
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
    List<double> matchResults = [
      1.0,
      11.0,
      2.0,
      0.0,
      14.0,
      2.0,
      14.0,
      21.0,
      14.0,
      21.0
    ];
    calculator(matchSchedule, matchResults,10,8);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), 27);
  });
  test("OPR5m4t", () {
    print("Test 3: 4 teams, 5 matches");
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0],
      [1.0, 0.0, 1.0, 0.0],
      [0.0, 1.0, 1.0, 0.0],
      [1.0, 0.0, 0.0, 1.0],
      [0.0, 1.0, 0.0, 1.0]
    ];
    List<double> matchResults = [
      10.0,
      13.0,
      7.0,
      15.0,
      10.0
    ];
    calculator(matchSchedule, matchResults,5,4);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), 8);
  });
  test("OPR3m4t", () {
    print("Test 4: 4 teams, 3 matches");
    List<List<double>> matchSchedule = [
      [1.0, 1.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 1.0],
      [1.0, 0.0, 1.0, 0.0]
    ];
    List<double> matchResults = [
      1.0,
      11.0,
      2.0
    ];
    calculator(matchSchedule, matchResults, 3,4);
    if(solutions.first.toString()=="NaN") {
      expect(solutions.first.toString(), "NaN");
      return;
    }
    expect(solutions.first.round(), double.infinity);
  });
}
void calculator(List<List<double>> a, List<double> b, int rows, int cols){
  /*
   * input: matches, results, rows: # of matches, cols: number of teams
   * m1: teams in matches
   * m2: match results
   * m3: transposed m1
   * m4: m3*m1 (opr system)
   * m5: m3*m2 (opr results)
   */
  Matrix<double> matchschedule = RealMatrix.fromData(
      columns: cols,
      rows: rows,
      data: a
  );

  Matrix<double> matchresults = RealMatrix.fromData(
      columns: 1,
      rows: matchschedule.rowCount,
      data: b.map((e) => [e]).toList()
  );

  //LUSolver formula to solve system of equations
  final lu = LUSolver(
      equations: (matchschedule.transpose()*matchschedule).toListOfList(),
      constants: (matchschedule.transpose()*matchresults).toList()
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