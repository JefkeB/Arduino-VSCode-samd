#include <Arduino.h>
#include <sam.h>


void setup();
void loop();


#define LED PB30

void setup()
{
    //pinMode(LED, OUTPUT);
    
	// pin PB30 output 
	PORT->Group[1].DIR.reg |= PORT_PB30;
	PORT->Group[1].OUTCLR.reg = PORT_PB30;
}

int cnt = 0;

void loop()
{ 
    //digitalWrite(LED, HIGH);    
	PORT->Group[PORTB].OUTTGL.reg = PORT_PB30;
    delay(100);
    //digitalWrite(LED, LOW);    
	PORT->Group[PORTB].OUTTGL.reg = PORT_PB30;
    delay(500);
}

#if 0
// This function prevents that the compilation ends with next error message
// "undefined reference to `std::__throw_bad_function_call()'"
// TODO: find out how to do this better
//
namespace std {
    void __throw_bad_function_call() {
        Serial.println(F("STL ERROR - __throw_bad_function_call"));
        __builtin_unreachable();
    }
}
#endif