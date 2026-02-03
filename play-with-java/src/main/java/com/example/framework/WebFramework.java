package com.example.framework;

import java.lang.reflect.Method;

public class WebFramework {


    public void handleHttpRequest(String url) {
        // parse the request
        // validate the request
        // conversion
        // auth & authorization
        // map request to thread
        //...
        try {
            Class<?> clazz = Class.forName("com.example.component.UserController");
            Method[] methods=clazz.getMethods();
            for(Method method:methods){
               RequestMapping rm= method.getAnnotation(RequestMapping.class);
               if(rm!=null){
                   String mappedUrl= rm.url();
                   if(mappedUrl.equals(url)){
                          try {
                            Object obj= clazz.getDeclaredConstructor().newInstance();
                            method.invoke(obj);
                          } catch (Exception e) {
                              throw new RuntimeException(e);
                          }
                   }
               }
            }
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

}
