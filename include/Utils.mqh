//+------------------------------------------------------------------+
//|                                                        utils.mqh |
//|                               Copyright 2025, Maxime Bourdouxhe. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Maxime Bourdouxhe."
#property link      "https://www.mql5.com"

#include <ErrorDescription.mqh>

struct IndicatorRef {
   int handle;
   string name;

   IndicatorRef() {
      handle = INVALID_HANDLE;
      name = "";
   }

   IndicatorRef(int h, string n) {
      handle = h;
      name = n;
   }
};

enum LogLevels {
    DEBUG,
    INFO,
    ERROR,
    CRITICAL
};

LogLevels Level = ERROR;

//+------------------------------------------------------------------+
//| Safe Copy Buffer                                                 |
//+------------------------------------------------------------------+
bool SafeCopyBuffer(const IndicatorRef &indicator, int bufferIndex, int startPos, int count, double &outBuffer[]) {
    if(indicator.handle == INVALID_HANDLE) {
        int err = GetLastError();
        PrintLog(__FUNCTION__, indicator.name + " indicator handle is invalid ! Error: " + ErrorDescription(err), ERROR);
        return(false);
    }
    
    ArraySetAsSeries(outBuffer, true);
            
    if(CopyBuffer(indicator.handle, bufferIndex, startPos, count, outBuffer) != count) {
        int err = GetLastError();
	    PrintLog(__FUNCTION__, " Failed to copy " + indicator.name + " buffer ! Error: " + ErrorDescription(err), ERROR);
	    return(false);
	}
    return(true);
}

//+------------------------------------------------------------------+
//| Verify Numbers Of Bars                                           |
//+------------------------------------------------------------------+
bool IsEnoughBars(string symbol, int barsRequired) {
    if(symbol == "" || symbol == NULL) return(false);
    
    if(Bars(symbol, PERIOD_CURRENT) < barsRequired) {
        PrintLog(__FUNCTION__, " Not enough bars, waiting ...", INFO);
        return(false);
    }
    return(true);
}

//+------------------------------------------------------------------+
//| Print Log                                                        |
//+------------------------------------------------------------------+
void PrintLog(string function, string message, LogLevels level) {

    if(Level == CRITICAL && level != CRITICAL) return;
    if(Level == ERROR && (level != ERROR && level != CRITICAL)) return;
    if(Level == INFO && level == DEBUG) return;
    
    string loglevel;
    
    if(level == DEBUG) loglevel =         "DEBUG: ";
    else if(level == INFO) loglevel =     "INFO: ";
    else if(level == ERROR) loglevel =    "ERROR: ";
    else if(level == CRITICAL) loglevel = "CRITICAL: ";
    
    Print(loglevel, function + "()", " " + message);
}

//+------------------------------------------------------------------+
//| Set Chart Style                                                  |
//+------------------------------------------------------------------+
void StyleChart(void) {
    long chart_id = ChartID();
    
    // Remove Grid
    ChartSetInteger(chart_id, CHART_SHOW_GRID, false);
    
    // Shift chart
    ChartSetInteger(chart_id, CHART_SHIFT, true);
    
    // Unzoom
    ChartSetInteger(chart_id, CHART_SCALE, ChartGetInteger(0, CHART_SCALE) - 1);
    
    // Background
    ChartSetInteger(chart_id, CHART_COLOR_BACKGROUND, 0, clrWhite);
    
    // Foreground (axes/text)
    ChartSetInteger(chart_id, CHART_COLOR_FOREGROUND, 0, clrBlack);
    
    // Remove grid
    ChartSetInteger(chart_id, CHART_SHOW_GRID, false);
    
    // Candle Colors
    ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BULL, 0, clrLime);
    ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BEAR, 0, clrRed);
    
    // Wick colors (optional)
    ChartSetInteger(chart_id, CHART_COLOR_CHART_UP, 0, clrLimeGreen);
    ChartSetInteger(chart_id, CHART_COLOR_CHART_DOWN, 0, clrRosyBrown);
    
    // Remove volume
    ChartSetInteger(chart_id, CHART_SHOW_VOLUMES, false);
    
    // Show Bid & Ask lines
    ChartSetInteger(0, CHART_SHOW_BID_LINE, true);
    ChartSetInteger(0, CHART_SHOW_ASK_LINE, true);
    
    // Color Bid & Ask lines
    ChartSetInteger(0, CHART_COLOR_BID, clrRed);
    ChartSetInteger(0, CHART_COLOR_ASK, clrLime);
}
