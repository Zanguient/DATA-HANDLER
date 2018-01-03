//+------------------------------------------------------------------+
//|                                PRICE ACTION MACHINE LEARNING.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <data_handler.mqh>
#include <mt4_lib.mqh>
#include <MQLMySQL.mqh>

MT4_Lib mt4;
data_handler d;
struct Rdata      {string field[];};
//// EA PARAMETER ///
extern int EA_Magic = 88729;
//// TRAINING PARAMETER ////
//int maxbar_allowed = TerminalInfoInteger(TERMINAL_MAXBARS);
int maxbar_allowed = 10000;
//extern string = "PERIOD_M15";
extern int Reversal_Candle = 5; //How many units of candles to look back and trend for the detection of reversal trend

extern double Similar_Percentage = 99; //
extern int Min_TP = 40; //tp set in 4 digits trade
extern double Open_Trade_Accuracy =75;
extern int training_hour_interval =24; //we train every 24 hours
//double spread = SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID);
//double pip = spread/2; //pip in 5 digits count
//// ARRAY   ////
double DoubleArray [];
double CandleData [];
double test_array [];
datetime time;
datetime timestart;
datetime training_time;
double buy, sell, loss, total_record; //1,2,3
//EDIT THESE PARAMETER TO SUITE THE NEED OF YOUR DATABASE
   
   


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // INITIALIZATION FOR MT4_LIB.MQH
   mt4.setPeriod(_Period);    // sets the chart period/timeframe
   mt4.setSymbol(_Symbol);
   mt4.setMagic(EA_Magic);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    if (training_time_elapsed()==true)
    {
       train();
    }
    if(mt4.isNewBar()>0)
    {     
      if (trade_analyse(1)==false)  //we check the previous newly formed candle, if opportunities exist, we update to Db, else delete from Database
      {
         delete_from_db();
      }
    }
    
  }
bool training_time_elapsed ()
{
    if (training_time==0)
    {
       training_time=TimeCurrent();
       return(true);
    }
    else
    {
       if (TimeCurrent()-training_time>training_hour_interval*60*60)
       {
          training_time=TimeCurrent();
          return(true);
       }
    }
 return(false);
}  
double pip ()
{
   string symbol = _Symbol;
   
   if (StringFind(symbol,"BTC",0)==0 | StringFind(symbol,"ETH",0)==0)
   {
      double spread = SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double pip = spread/2; //pip in 5 digits count
      return (pip);  //divide by 10 to suite 5 dp point
   }
   
   if (SymbolInfoInteger(_Symbol,SYMBOL_DIGITS)==4)
   {
       return(SymbolInfoDouble(_Symbol,SYMBOL_POINT));
   }
   return(SymbolInfoDouble(_Symbol,SYMBOL_POINT)*10); //5 digits      
}

void get_current_candle_data (int input_bar)  //this is the part where you change the pattern of learning
{
    ZeroMemory(CandleData);
    ArrayResize(CandleData,(Reversal_Candle-1)*8,(Reversal_Candle-1)*8);
    int size = ArraySize(CandleData);
    //follow the pattern OHLC
    
    //1. Fifth and Fourth Candle
    CandleData[0]=(mt4.Open(input_bar+Reversal_Candle-(2))-mt4.Open(input_bar+Reversal_Candle-(1)))/mt4.Open(input_bar+Reversal_Candle-(1));
    CandleData[1]=(mt4.High(input_bar+Reversal_Candle-(2))-mt4.High(input_bar+Reversal_Candle-(1)))/mt4.High(input_bar+Reversal_Candle-(1));  
    CandleData[2]=(mt4.Low(input_bar+Reversal_Candle-(2))-mt4.Low(input_bar+Reversal_Candle-(1)))/mt4.Low(input_bar+Reversal_Candle-(1)); 
    CandleData[3]=(mt4.Close(input_bar+Reversal_Candle-(2))-mt4.Close(input_bar+Reversal_Candle-(1)))/mt4.Close(input_bar+Reversal_Candle-(1)); 
    
    //2. Fourth and Third Candle
    CandleData[4]=(mt4.Open(input_bar+Reversal_Candle-(3))-mt4.Open(input_bar+Reversal_Candle-(2)))/mt4.Open(input_bar+Reversal_Candle-(2));
    CandleData[5]=(mt4.High(input_bar+Reversal_Candle-(3))-mt4.High(input_bar+Reversal_Candle-(2)))/mt4.High(input_bar+Reversal_Candle-(2));  
    CandleData[6]=(mt4.Low(input_bar+Reversal_Candle-(3))-mt4.Low(input_bar+Reversal_Candle-(2)))/mt4.Low(input_bar+Reversal_Candle-(2)); 
    CandleData[7]=(mt4.Close(input_bar+Reversal_Candle-(3))-mt4.Close(input_bar+Reversal_Candle-(2)))/mt4.Close(input_bar+Reversal_Candle-(2)); 

    //3. Third and Second Candle
    CandleData[8]=(mt4.Open(input_bar+Reversal_Candle-(4))-mt4.Open(input_bar+Reversal_Candle-(3)))/mt4.Open(input_bar+Reversal_Candle-(3));
    CandleData[9]=(mt4.High(input_bar+Reversal_Candle-(4))-mt4.High(input_bar+Reversal_Candle-(3)))/mt4.High(input_bar+Reversal_Candle-(3));  
    CandleData[10]=(mt4.Low(input_bar+Reversal_Candle-(4))-mt4.Low(input_bar+Reversal_Candle-(3)))/mt4.Low(input_bar+Reversal_Candle-(3)); 
    CandleData[11]=(mt4.Close(input_bar+Reversal_Candle-(4))-mt4.Close(input_bar+Reversal_Candle-(3)))/mt4.Close(input_bar+Reversal_Candle-(3)); 
    
    //4. Second and Input Candle
    CandleData[12]=(mt4.Open(input_bar+Reversal_Candle-(5))-mt4.Open(input_bar+Reversal_Candle-(4)))/mt4.Open(input_bar+Reversal_Candle-(4));
    CandleData[13]=(mt4.High(input_bar+Reversal_Candle-(5))-mt4.High(input_bar+Reversal_Candle-(4)))/mt4.High(input_bar+Reversal_Candle-(4));  
    CandleData[14]=(mt4.Low(input_bar+Reversal_Candle-(5))-mt4.Low(input_bar+Reversal_Candle-(4)))/mt4.Low(input_bar+Reversal_Candle-(4)); 
    CandleData[15]=(mt4.Close(input_bar+Reversal_Candle-(5))-mt4.Close(input_bar+Reversal_Candle-(4)))/mt4.Close(input_bar+Reversal_Candle-(4));
    
    
    //   Finding body, length, head to body ratio and tail to body ratio  //
                
                //A. Find Length
                double length_4=mt4.High(input_bar+Reversal_Candle-2)-mt4.Low(input_bar+Reversal_Candle-2);//find length 4
                double length_3=mt4.High(input_bar+Reversal_Candle-3)-mt4.Low(input_bar+Reversal_Candle-3);//find length 3
                double length_2=mt4.High(input_bar+Reversal_Candle-4)-mt4.Low(input_bar+Reversal_Candle-4);//find length 2
                double length_1=mt4.High(input_bar+Reversal_Candle-5)-mt4.Low(input_bar+Reversal_Candle-5);//find length 1
                
                //B. Find Open
                double open_4=mt4.Open(input_bar+Reversal_Candle-2);//find high 4
                double open_3=mt4.Open(input_bar+Reversal_Candle-3);//find high 3
                double open_2=mt4.Open(input_bar+Reversal_Candle-4);//find high 2
                double open_1=mt4.Open(input_bar+Reversal_Candle-5);//find high 1
                
                //C. Find High
                double high_4=mt4.High(input_bar+Reversal_Candle-2);//find high 4
                double high_3=mt4.High(input_bar+Reversal_Candle-3);//find high 3
                double high_2=mt4.High(input_bar+Reversal_Candle-4);//find high 2
                double high_1=mt4.High(input_bar+Reversal_Candle-5);//find high 1
                
                //D. Find Low
                double low_4=mt4.Low(input_bar+Reversal_Candle-2);//find low 4
                double low_3=mt4.Low(input_bar+Reversal_Candle-3);//find low 3
                double low_2=mt4.Low(input_bar+Reversal_Candle-4);//find low 2
                double low_1=mt4.Low(input_bar+Reversal_Candle-5);//find low 1
                
                //E. Find Close
                double close_4=mt4.Close(input_bar+Reversal_Candle-2);//find low 4
                double close_3=mt4.Close(input_bar+Reversal_Candle-3);//find low 3
                double close_2=mt4.Close(input_bar+Reversal_Candle-4);//find low 2
                double close_1=mt4.Close(input_bar+Reversal_Candle-5);//find low 1
      
      //**********FORMAT : BODY, LENGTH, HEAD TO BODY RATIO, HEAD TO TAIL RATIO**************//
     // 5. For 4th candle
     if (close_4>open_4)//bull candle
     {
        CandleData[16]=close_4-open_4;  CandleData[17]=length_4; CandleData[18]=(high_4-close_4)/(close_4-open_4); CandleData[19]=(open_4-low_4)/(close_4-open_4);
     }
     if (close_4<open_4)//bear candle
     {
        CandleData[16]=open_4-close_4;  CandleData[17]=length_4; CandleData[18]=(high_4-open_4)/(open_4-close_4); CandleData[19]=(close_4-low_4)/(open_4-close_4);
     }
     if (close_4==open_4)//neutral candle, to prevent divide by zero error, we jx presume the body is super small, which is 0.00001
     {
        CandleData[16]=1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);  CandleData[17]=length_4; CandleData[18]=(high_4-close_4)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT); CandleData[19]=(open_4-low_4)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
     }
     
     
     // 6. For 3rd candle
     if (close_3>open_3)//bull candle
     {
        CandleData[20]=close_3-open_3;  CandleData[21]=length_3; CandleData[22]=(high_3-close_3)/(close_3-open_3); CandleData[23]=(open_3-low_3)/(close_3-open_3);
     }
     if (close_3<open_3)//bear candle
     {
        CandleData[20]=open_3-close_3;  CandleData[21]=length_3; CandleData[22]=(high_3-open_3)/(open_3-close_3); CandleData[23]=(close_3-low_3)/(open_3-close_3);
     }
     if (close_3==open_3)//neutral candle
     {
        CandleData[20]=1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);  CandleData[21]=length_3; CandleData[22]=(high_3-close_3)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT); CandleData[23]=(open_3-low_3)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
     }
     
     // 7. For 2nd candle
     if (close_2>open_2)//bull candle
     {
        CandleData[24]=close_2-open_2;  CandleData[25]=length_2; CandleData[26]=(high_2-close_2)/(close_2-open_2); CandleData[27]=(open_2-low_2)/(close_2-open_2);
     }
     if (close_2<open_2)//bear candle
     {
        CandleData[24]=open_2-close_2;  CandleData[25]=length_2; CandleData[26]=(high_2-open_2)/(open_2-close_2); CandleData[27]=(close_2-low_2)/(open_2-close_2);
     }
     if (close_2==open_2)//neutral candle
     {
        CandleData[24]=1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);  CandleData[25]=length_2; CandleData[26]=(high_2-close_2)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT); CandleData[27]=(open_2-low_2)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
     }
     
     // 8. For 1st candle
     if (close_1>open_1)//bull candle
     {
        CandleData[28]=close_1-open_1;  CandleData[29]=length_1; CandleData[30]=(high_1-close_1)/(close_1-open_1); CandleData[31]=(open_1-low_1)/(close_1-open_1);
     }
     if (close_1<open_1)//bear candle
     {
        CandleData[28]=open_1-close_1;  CandleData[29]=length_1; CandleData[30]=(high_1-open_1)/(open_1-close_1); CandleData[31]=(close_1-low_1)/(open_1-close_1);
     }
     if (close_1==open_1)//bull candle
     {
        CandleData[28]=1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);  CandleData[29]=length_1; CandleData[30]=(high_1-close_1)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT); CandleData[31]=(open_1-low_1)/1*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
     }
   
}

int maxbar () //this function to serve to find the continuation from the last training end point
{
   if (d.get_latest_date()!=0)
   {
      Alert (Symbol()+" Continue Last Trading at bar "+mt4.iBarShift(d.get_latest_date()));
      return(mt4.iBarShift(d.get_latest_date()));
   }
  return(maxbar_allowed);
}

bool bull_reversal_pattern (int input_bar)
{
   int candle     = Reversal_Candle-1;
   double Highest = mt4.iHighestPrice(input_bar,candle); //count 5 times including self candle
   double Lowest  = mt4.iLowestPrice(input_bar,candle);
   double Close   = mt4.Close(input_bar);
   
   for (int i=input_bar-1;i>0;i--)
   {
        if (mt4.iHighestPrice(i,input_bar-i+1)-Close>=Min_TP*pip())  //bull reversal
        {
          
             if (mt4.iLowestPrice(i,input_bar-i+1)>Lowest)  // meaning the bull trend did not hit sl  ***Initial is lowest
             {
                  if (Min_TP*pip()>=(Close-Lowest)/2)  //meaning reward risk ratio at least 2
                  {
                     return(true);
                  }
             }
             break;
        }
   }
   
   return(false);
}

bool bear_reversal_pattern (int input_bar)
{
   int candle     = Reversal_Candle-1;
   double Highest = mt4.iHighestPrice(input_bar,candle); //count 5 times including self candle
   double Lowest  = mt4.iLowestPrice(input_bar,candle);
   double Close   = mt4.Close(input_bar);
   
   for (int i=input_bar-1;i>0;i--)
   {
     //Alert(Min_TP*pip);
        if (Close-mt4.iLowestPrice(i,input_bar-i+1)>=Min_TP*pip())  //bear reversal
        {
          
             if (mt4.iHighestPrice(i,input_bar-i+1)<Highest)  // meaning the bull trend did not hit sl  ********Initial Is Lowest
             {
               
                  if (Min_TP*pip()>=(Highest-Close)/2)  //meaning reward risk ratio at least 2
                  {
                     return(true);
                  }
             }
             break;
        }
   }
   
   return(false);
}

bool loss_pattern (int input_bar)
{
   int candle     = Reversal_Candle-1;
   double Highest = mt4.iHighestPrice(input_bar,candle); //count 5 times including self candle
   double Lowest  = mt4.iLowestPrice(input_bar,candle);
   double Close   = mt4.Close(input_bar);
   
   if (bull_reversal_pattern(input_bar)==false && bear_reversal_pattern(input_bar)==false)  //meaning both type loss
   {
      
     for (int i=input_bar-1;i>0;i--)
     {
     
        if (mt4.iHighestPrice(i,input_bar-i+1)-Close>=Min_TP*pip()/2)  //meaning bull trend in limit order tp
        {
            if (mt4.iLowestPrice(i,input_bar-i+1)>Lowest-(Min_TP*pip())/2) //meaning not hitting the sl
            {
               if (mt4.iLowestPrice(i,input_bar-i+1)<Lowest) //meaning limit trade can be triggered
               {
                  return(true);
               }
            }
        
        }
        
        if (Close-mt4.iLowestPrice(i,input_bar-i+1)>=Min_TP*pip()/2)  //meaning bear trend in limit order tp
        {
            if (mt4.iHighestPrice(i,input_bar-i+1)<Highest+(Min_TP*pip())/2) //meaning not hitting the sl
            {
               if (mt4.iHighestPrice(i,input_bar-i+1)>Highest) //meaning limit trade can be triggered
               {
                  return(true);
               }
            }
        
        }
            
     } 
   }
   
   return(false);
}

bool pattern_matcher (double &data[])  //function complete, just plugin and insert array data as matcher
{
  if (d.pattern_matcher(Similar_Percentage,data)==true)
  {
      //Alert("Yes Matching");
      return(true);
  }
  //Alert("Not Matching");
  return(false);
}


void record_new_pattern (int input_bar, int type)  //just adjust the input value, and convert it into array for data inserting
{  
   datetime time=mt4.iTime(input_bar);
   ZeroMemory(CandleData);
   get_current_candle_data(input_bar);
   int size = ArraySize(CandleData);
   ArrayResize(CandleData,size+3,size+3);  //we add 3 more array to accomodate the type
   if (type==1) //bullish
   {
      CandleData[size]=1;
      CandleData[size+1]=0;
      CandleData[size+2]=0;
   }
   
   if (type==2) //bearish
   {
      CandleData[size]=0;
      CandleData[size+1]=1;
      CandleData[size+2]=0;
   }
   
   if (type==3) //loss
   {
      CandleData[size]=0;
      CandleData[size+1]=0;
      CandleData[size+2]=1;
   }
   
   d.record(time, CandleData);
}

void train ()  //find the new pattern of trading
{
   //Max
  string working_folder=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"; 
  string working_file=working_folder+Files;
      
   if (FileIsExist(Files,working_folder)) //meaning file is exist, so we just find the old pattern to match first before looking for new one
   {
     Print ("---------"+Symbol()+" Continue From Last Training------------");
     for (int i=maxbar()-Reversal_Candle+1; i>0; i--)
     { 
          Print ("--------"+Symbol()+" Current Training Bar Is"+i+"----------");
          
           timestart = TimeCurrent();
      
          get_current_candle_data(i);
   
          if (pattern_matcher(CandleData)==true) //meaning similar pattern exist in database
          {
            //if true, then we need to vote the candle
              if (bull_reversal_pattern(i)==true) //meaning this is strong evidence for bull
              {
                d.vote(d.vote_line,1); //1 is bull, 2 is bear, 3 is loss
                Print(Symbol()+" Update Bull Vote For Candle "+i+" In Line "+d.vote_line);
              }
             else
             {
                  if (bear_reversal_pattern(i)==true) //meaning this is strong evidence for bear
                  {
                      d.vote(d.vote_line,2); //1 is bull, 2 is bear, 3 is loss
                      Print(Symbol()+" Update Bear Vote For Candle "+i+" In Line "+d.vote_line);
                  }
              
                  if (loss_pattern(i)==true)  //meaning hitting the stop loss for both
                  {
                      d.vote(d.vote_line,3); //1 is bull, 2 is bear, 3 is loss
                      Print(Symbol()+" Update Loss Vote For Candle "+i+" In Line "+d.vote_line);
                  }
              }
           
                  
             }
      
             else  //meaning this is possible a new pattern
             {
                  if (bull_reversal_pattern(i)==true)
                  {
                     record_new_pattern(i,1);
                     Print(Symbol()+" Update New Bull Pattern At Candle "+i);
                  }
                  if (bear_reversal_pattern(i)==true)
                  {
                     record_new_pattern(i,2);
                     Print(Symbol()+" Update New Bear Pattern At Candle "+i);
                  }
                  if (loss_pattern(i)==true)  //meaning hitting the stop loss for both   ///******NEW*******
                  {
                      record_new_pattern(i,3); //1 is bull, 2 is bear, 3 is loss
                      Print(Symbol()+" Update New Loss Pattern For Line "+d.vote_line);
                  }
             }
      }
    }
    
    else   //file not exist, so we just find new pattern and update accordingly
    {
    
       Print ("---------"+Symbol()+" Initializing New Training------------");
       for (int i=maxbar_allowed-Reversal_Candle+1; i>0; i--)
       {
               Print ("--------"+Symbol()+" Current Training Bar Is"+i+"----------");
               timestart = TimeCurrent();
               
               
           if (pattern_matcher(CandleData)==true) //meaning similar pattern exist in database
          {
            //if true, then we need to vote the candle
              if (bull_reversal_pattern(i)==true) //meaning this is strong evidence for bull
              {
                d.vote(d.vote_line,1); //1 is bull, 2 is bear, 3 is loss
                Print(Symbol()+" Update Bull Vote For Candle "+i+" In Line "+d.vote_line);
              }
             else
             {
                  if (bear_reversal_pattern(i)==true) //meaning this is strong evidence for bear
                  {
                      d.vote(d.vote_line,2); //1 is bull, 2 is bear, 3 is loss
                      
                      Print(Symbol()+" Update Bear Vote For Candle "+i+" In Line "+d.vote_line);
                  }
              
                  if (loss_pattern(i)==true)  //meaning hitting the stop loss for both
                  {
                      d.vote(d.vote_line,3); //1 is bull, 2 is bear, 3 is loss
                      Print(Symbol()+" Update Loss Vote For Candle "+i+" In Line "+d.vote_line);
                  }
              }
           
                  Print(Symbol()+" Update Vote For Candle "+i+" In Line "+d.vote_line);
             }
      
             else  //meaning this is possible a new pattern
             {
                  if (bull_reversal_pattern(i)==true)
                  {
                     record_new_pattern(i,1);
                     Print(Symbol()+" Update New Bull Pattern At Candle "+i);
                  }
                  if (bear_reversal_pattern(i)==true)
                  {
                     record_new_pattern(i,2);
                     Print(Symbol()+" Update New Bear Pattern At Candle "+i);
                  }
                  if (loss_pattern(i)==true)  //meaning hitting the stop loss for both   ///******NEW*******
                  {
                      record_new_pattern(i,3); //1 is bull, 2 is bear, 3 is loss
                      Print(Symbol()+" Update New Loss Pattern For Line "+d.vote_line);
                  }
             }
                Print(Symbol()+" No Pattern Recorded For Bar "+i);
       }
    }
      
    
      
      
      
      
   
   
}

bool trade_analyse (int input_bar)  //if false delete entry
{
   
   int candle     = Reversal_Candle-1;
   double Highest = mt4.iHighestPrice(input_bar,candle); //count 5 times including self candle
   double Lowest  = mt4.iLowestPrice(input_bar,candle);
   double Close   = mt4.Close(input_bar);
   get_current_candle_data(input_bar); //get the data first
   
   //Alert("Candle Data 2 is "+CandleData[1]);
   if (pattern_matcher(CandleData)==true)
   {
      
       buy = d.fetch_data(d.vote_line,d.total_field_size-3);
       sell = d.fetch_data(d.vote_line,d.total_field_size-2);
       loss = d.fetch_data(d.vote_line,d.total_field_size-1);
       //Alert("Hello Line Is"+d.vote_line);
        if (buy!=0 | sell!=0 | loss!=0) //meaning we are fetching correctly
        {
              total_record=buy+sell+loss;
             
              if (total_record>10)//we need quality data
              {
               //Alert("Total Record Is "+total_record);
               //Alert("Buy Is "+buy);
               //Alert("Sell Is "+sell);
               //Alert("Loss Is "+loss);
                  if ((buy/total_record)*100>=Open_Trade_Accuracy)//meaning there is a buy opportunity
                  {
                     update_db(1, Min_TP, Close, Highest, Lowest);
                     return(true);
                  }
                  
                  if ((sell/total_record)*100>=Open_Trade_Accuracy)
                  {
                     update_db(1, Min_TP, Close, Highest, Lowest);
                     return(true);
                  }
                  
                  if ((loss/total_record)*100>=Open_Trade_Accuracy)
                  {
                     //Alert("Send Loss Is "+loss);
                     update_db(3, Min_TP, Close, Highest, Lowest);
                     return(true);
                  }     
              
              
              }
        }
   }
   return(false);
}


void update_db (int type, int tp_point, double close, double highest, double lowest)
{
    database_update_multiple_query(type,"TP",tp_point,"CLOSE",close,"HIGHEST",highest,"LOWEST",lowest);

}

void delete_from_db ()
{
   database_delete_entry();
}

void fetch_type ()
{
   Print (database_fetch_integer("TYPE"));
}





//+------------------------------------------------------------------+

