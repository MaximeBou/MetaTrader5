//+------------------------------------------------------------------+
//|                                            ChecksBeforeTrade.mqh |
//|                               Copyright 2025, Maxime Bourdouxhe. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Maxime Bourdouxhe."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Verify Volume & Money                                            |
//+------------------------------------------------------------------+
bool CheckVolumeMoney(double lot, ENUM_ORDER_TYPE type, string symbol) {
    string err_text = "";
	if(!CheckVolumeValue(lot, err_text, symbol)) {
	    PrintLog(__FUNCTION__, err_text, ERROR);
	    return(false);
	}
	
	if(!CheckMoneyForTrade(symbol, lot, type)) {
        return(false);
    }
    return(true);
}

//+------------------------------------------------------------------+
//| Verify StopLoss & TakeProfit Before Trade                        |
//+------------------------------------------------------------------+
bool CheckStopLossTakeprofit(ENUM_POSITION_TYPE type, double SL, double TP) {
    // No check needed when SL && TP = 0
    if(SL == 0 && TP == 0) return(true);
    
    
    // Get the SYMBOL_TRADE_STOPS_LEVEL level
    int stops_level = (int)SymbolInfoInteger(m_symbol.Name(), SYMBOL_TRADE_STOPS_LEVEL);
    if(stops_level != 0) {
        PrintFormat(
            " SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must" +
            " not be nearer than %d points from the closing price", stops_level, stops_level
        );
    }

    bool SL_check = false, TP_check = false;
    double Bid = m_symbol.Bid(), Ask = m_symbol.Ask();
    
    // Check only two order types
    switch(type) {
        case POSITION_TYPE_BUY: {
             // Check StopLoss
             SL_check = (Bid - SL > stops_level * adjusted_point);
             if(!SL_check)
                PrintFormat(
                    "For order %s StopLoss=%.5f must be less than %.5f" +
                    " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL = %d points)",
                    EnumToString(type), SL, Bid - stops_level * adjusted_point, Bid, stops_level
                );
             
             // Check TakeProfit
             TP_check=(TP - Bid > stops_level * adjusted_point);
             if(!TP_check)
                PrintFormat(
                    "For order %s TakeProfit=%.5f must be greater than %.5f" +
                    " (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL = %d points)",
                    EnumToString(type), TP, Bid + stops_level * adjusted_point, Bid, stops_level
                );
            return(SL_check && TP_check);
            
        } case POSITION_TYPE_SELL: {
            // Check StopLoss
            SL_check = (SL - Ask > stops_level * adjusted_point);
            if(!SL_check) {
                PrintFormat(
                    "For order %s StopLoss=%.5f must be greater than %.5f " +
                    " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                    EnumToString(type), SL, Ask + stops_level * adjusted_point, Ask, stops_level
                );
            }
            
            // Check TakeProfit
            TP_check=(Ask - TP > stops_level * adjusted_point);
            if(!TP_check) {
                PrintFormat(
                    "For order %s TakeProfit=%.5f must be less than %.5f "+
                    " (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                    EnumToString(type), TP, Ask - stops_level * adjusted_point, Ask, stops_level
                );
            }
            return(TP_check && SL_check);
        }
        break;
    }
    return(false);
}

//+------------------------------------------------------------------+
//| Verify Volume Before Trade                                       |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume, string &error_description, string symbol) {
    // Minimal allowed volume
    double min_volume = m_symbol.LotsMin();
    if(volume < min_volume) {
        error_description = StringFormat(
            "Volume is less than the minimal allowed SYMBOL_VOLUME_MIN = %.2f", min_volume
        );
        return(false);
    }

    double max_volume = m_symbol.LotsMax();

   
    // Check volume limit
    double limit_volume = SymbolInfoDouble(m_symbol.Name(), SYMBOL_VOLUME_LIMIT);
    double current_volume_total = GetTotalVolume(symbol);
    if(limit_volume - current_volume_total - volume <= 0 && limit_volume > 0) {
        error_description = StringFormat(
            "Volume Limit reached SYMBOL_VOLUME_LIMIT = %.2f", limit_volume
        );
        return(false);
    }
    
    // Maximal allowed volume for symbol
    if(volume > max_volume) {
        error_description = StringFormat(
            "Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX = %.2f", max_volume
        );
        return(false);
    }
    
    // Volume step 
    double volume_step = m_symbol.LotsStep();
    int ratio = (int)MathRound(volume / volume_step);
    if(MathAbs(ratio * volume_step-volume) > 0.0000001) {
        error_description = StringFormat(
            "Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP = %.2f, the closest correct volume is %.2f",
            volume_step, ratio*volume_step
        );
        return(false);
    }
    error_description = "Correct volume value";
    return(true);
}

//+------------------------------------------------------------------+
//| Get Total Volume Of Bot Positions                                |
//+------------------------------------------------------------------+
double GetTotalVolume(string symbol) {
    int pos_total = PositionsTotal()-1;
    ulong ticket = 0;
    double volume = 0;
    
    for(int i = pos_total; i >= 0; i--) {
        if(!(ticket = PositionGetTicket(i))) continue;
        
        if(PositionGetString(POSITION_SYMBOL) == symbol) {
            volume += PositionGetDouble(POSITION_VOLUME);
        }
    }
    pos_total = OrdersTotal();

    for(int i = pos_total; i >= 0; i--) {
        if(!(ticket = OrderGetTicket(i))) continue;
        
        if(OrderGetString(ORDER_SYMBOL) == symbol) {
            volume += OrderGetDouble(ORDER_VOLUME_CURRENT);
        }
    }
    PrintLog(__FUNCTION__, "Volume: " + string(volume), DEBUG);
    return(volume);
}

//+------------------------------------------------------------------+
//| Verify Money Before Trade                                        |
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb, double lots, ENUM_ORDER_TYPE type) {
    MqlTick mqltick;
    SymbolInfoTick(symb, mqltick);
    
    double price = mqltick.ask;
    if(type == ORDER_TYPE_SELL) {
        price = mqltick.bid;
    }

    double margin, free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

    if(!OrderCalcMargin(type, symb, lots, price, margin)) {
        int err = GetLastError();
        PrintLog(
            __FUNCTION__, "" + ErrorDescription(err),
            ERROR
        );
        return(false);
    }

    if(margin > free_margin) {
        int err = GetLastError();
        PrintLog(
            __FUNCTION__, "Not enough money for " + EnumToString(type) +
            " " + string(lots) + " " + symb + " Error code = " + ErrorDescription(err),
            ERROR
        );
        return(false);
    }
   return(true);
}