package com.example.day2;

import java.util.Arrays;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class Exercise3 {

    public static void main(String[] args) {

        String[] csvData = {
                "Name,Department,Salary",
                "Alice,Engineering,70000",
                "Bob,HR,50000",
                "Charlie,Engineering,80000",
                "Diana,Marketing,60000"
        };

        // note : department names not known in advance

        // output:
        // Engineering: 150000
        // HR: 50000
        // Marketing: 60000


        // way-1 : imperative approach
//        System.out.println("Way-1 : Imperative approach");
        Map<String, Double> deptSalaryMap = new java.util.HashMap<>();
        for (int i = 1; i < csvData.length; i++) {
            String line = csvData[i];
            String[] parts = line.split(",");
            String department = parts[1];
            double salary = Double.parseDouble(parts[2]);
//            if (deptSalaryMap.containsKey(department)) {
//                double existingSalary = deptSalaryMap.get(department);
//                deptSalaryMap.put(department, existingSalary + salary);
//            } else {
//                deptSalaryMap.put(department, salary);
//            }
            deptSalaryMap.put(department, deptSalaryMap.getOrDefault(department, 0.0) + salary);
        }
//        System.out.println(deptSalaryMap);

        // way-2 : declarative approach
        Map<String, Double> depSalMap = Stream.of(csvData)
                .skip(1)
                .map(line -> line.split(","))
                .collect(Collectors.groupingBy(
                        parts -> parts[1],
                        Collectors.summingDouble(parts -> Double.parseDouble(parts[2]))
                ));

        System.out.println(depSalMap);


    }

}
