package com.example.day3;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Calendar;
import java.util.Date;

public class Temporal_Data_Example {
    public static void main(String[] args) {

        Date currentDate = new Date();
        // limitations of Date class
        // - mutability
        // - design flaws

        Calendar calendar = Calendar.getInstance();
        calendar.setTime(currentDate);
        int year = calendar.get(Calendar.YEAR);
        int month = calendar.get(Calendar.MONTH) + 1; // Months are 0-based

        //-------------

        LocalDate localDate = LocalDate.now();
        LocalTime localTime = LocalTime.now();
        LocalDateTime localDateTime = LocalDateTime.now();

    }
}
