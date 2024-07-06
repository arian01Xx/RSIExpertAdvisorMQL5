#include <Trade/Trade.mqh>

CTrade trade;

double AccountRisk=0.01;// 1% of account balance
double Lots=0.1;
int takeProfits=100;
int stopLoss=100;

int magic=11;

int bollingerBands;
int Rsi;
int StochDef;
int handleTrendMaFast;
int handleTrendMaSlow;

int maxOrders=3;
int ordersOpened=0; //variable to count the number of opened orders
int totalPositions=PositionsTotal();
int openPositions=0;

double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);

int OnInit(){
   //Bollinger Bands 
   bollingerBands=iBands(_Symbol,PERIOD_M15,20,0,2,PRICE_CLOSE);
   
   //RSI
   Rsi=iRSI(_Symbol,PERIOD_M15,14,PRICE_CLOSE);
   
   //Stochastic
   StochDef=iStochastic(_Symbol,PERIOD_M15,14,3,3,MODE_SMA,STO_LOWHIGH);
   
   //MA indicator
   handleTrendMaFast=iMA(_Symbol, PERIOD_M15,8,0,MODE_EMA,PRICE_CLOSE);
   handleTrendMaSlow=iMA(_Symbol,PERIOD_M15,21,0,MODE_EMA,PRICE_CLOSE);
  
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){

   //Bollinger Bands
   double middleBandArray[];
   double upperBandArray[];
   double lownerBandArray[];
   
   ArraySetAsSeries(middleBandArray,true);
   ArraySetAsSeries(upperBandArray,true);
   ArraySetAsSeries(lownerBandArray,true);
   
   CopyBuffer(bollingerBands,0,0,3,middleBandArray);
   CopyBuffer(bollingerBands,1,0,3,upperBandArray);
   CopyBuffer(bollingerBands,2,0,3,lownerBandArray);
   
   double middleBandA=middleBandArray[0];
   double upperBandA=upperBandArray[0];
   double lownerBandA=lownerBandArray[0];
   
   //RSI
   double RSI[];
   ArraySetAsSeries(RSI,true); //sorting prices
   CopyBuffer(Rsi,0,0,1,RSI);
   double RSIvalue=NormalizeDouble(RSI[0],2);
   
   //MA indicator
   double maTrendFast[], maTrendSlow[];
   
   ArraySetAsSeries(maTrendFast,true);
   ArraySetAsSeries(maTrendSlow,true);
   
   CopyBuffer(handleTrendMaFast,0,0,3,maTrendFast);
   CopyBuffer(handleTrendMaSlow,1,0,3,maTrendSlow);
   
   double maFast=maTrendFast[0];
   double maSlow=maTrendSlow[0];
   
   //Stochastic
   double Karray[];
   double Darray[];
   
   ArraySetAsSeries(Karray,true);
   ArraySetAsSeries(Darray,true);
   
   CopyBuffer(StochDef,0,0,3,Karray);
   CopyBuffer(StochDef,1,0,3,Darray);
   
   double KValue0=Karray[0];
   double DValue0=Darray[0];
   
   double KValue1=Karray[1];
   double DValue1=Karray[1];
   
   //trade code
   ask=NormalizeDouble(ask,_Digits);
   bid=NormalizeDouble(bid,_Digits);
   
   //Flexible Risk
   double sl=ask-50*_Point; 
   double tp=bid+50*_Point;
   
   //buying
   double tpB=ask+takeProfits*_Point;
   double slB=ask-stopLoss*_Point;
   
   tpB=NormalizeDouble(tpB,_Digits);
   slB=NormalizeDouble(slB,_Digits);
   
   //selling
   double tpS=bid-takeProfits*_Point;
   double slS=bid+takeProfits*_Point;
   
   tpS=NormalizeDouble(tpS,_Digits);
   slS=NormalizeDouble(slS,_Digits);
   
   //Gestion de riesgo
   double accountBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   double maxRisk=accountBalance*AccountRisk;
   double slNew=100*_Point;
   double lotSize=maxRisk/slNew;
   
   //Gestion dinamica de StopLoss y TakeProfit
   for(int i=PositionsTotal()-1; i>=0; i--){
     if(PositionGetSymbol(i)==_Symbol && PositionGetInteger(POSITION_MAGIC)==magic){
       ulong ticket=PositionGetTicket(i);
       if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
         trade.PositionModify(ticket,sl,tp);
       }else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
         trade.PositionModify(ticket,bid+50*_Point,bid-100*_Point);
       }
     }
   }
   
   //Stop infinite Orders until maxOrders <= 3 
   for(int i=totalPositions-1; i>=0; i--){
     if(PositionSelect(i)){
       if(PositionGetString(POSITION_SYMBOL)==_Symbol){
         openPositions++;
       }
     }
   }
   
   if(openPositions<maxOrders){
     if(trade.Buy(Lots,_Symbol,ask,slB,tpB)|| trade.Sell(Lots,_Symbol,bid,slS,tpS)){
       ordersOpened++;
     }
   }
   
   if(openPositions>=maxOrders){
     ordersOpened=0;
   }
   
   //Strategy
   if(RSIvalue>50){  //Uptrend
     if(KValue0>DValue0){
        trade.Buy(Lots,_Symbol,ask,slB,tpB);
     }
   }
   if(RSIvalue<50){  //Downtrend
     if(KValue0<DValue0){
        trade.Sell(Lots,_Symbol,bid,slS,tpS);
     }
   }
}