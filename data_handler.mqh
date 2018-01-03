//+------------------------------------------------------------------+
//|                                                 data_handler.mqh |
//|                                                          Belibao |
//|                                          https://www.belibao.com |
//+------------------------------------------------------------------+
#property copyright "Belibao"
#property link      "https://www.belibao.com"


//+---------------------------------------------------------------------------------------------------------------+
//| Data Handler : This data handler aim to help to ease the retrieving and updating of data into csv file        |
//| For new record entry, just input an array will do                                                             |
//| For updating/vote, the line count is starting from zero, input the vote type (counting from behind) and line  |
//| will do the rest of the job.                                                                                  |
//+---------------------------------------------------------------------------------------------------------------+
class data_handler 
{
   private:
  
       void              create_new_file_record (datetime date, double &array[]);
       struct SLine      {string field[];};
       void              read_vote (int input_line);
       void              preprocessing_vote(string &field[]);
       void              rewrite_vote (int input_line);
       double            vote_buy;
       double            vote_sell;
       double            vote_loss;
       string            TmpFileName(string Name,string Ext);
       int               count;
       

   
   public:
       void              start  ();           ///serve as constructor
       void              record (datetime date, double &array[]);
       void              read   ();
       void              vote (int input_line, int input_vote);  //Input vote : 1 is buy, 2 is sell, 3 is loss
       bool              ReadFileToArrayCSV(string FileName,SLine & Lines[]);
       datetime          get_latest_date ();  ///get latest candle bar from old record
       double            fetch_data(int input_line, int input_field);
       bool              pattern_matcher(double percentage, double &check[]);
       int               vote_line;
       int               total_field_size;
   
   
   protected:
   
   

};

//To change to specific filename, just edit from here will do
//The default output folder in DataPath/MQL5/Files
string Files_Name = Symbol()+EnumToString(_Period);
string Files = Files_Name+".txt";
string preprocessing_string;

void data_handler::record(datetime date, double &array[])
{
   
   string str="";
   int size=ArraySize(array);
   if(size>0)
   {
      str=date+";"+array[0];
      for(int i=1;i<size;i++)
      {
         str=str+";"+array[i]; // merge fields using a separator
         
         if (i==size-1)
         {
           str=str+"\n";
         } 
      }
   }
   string working_folder=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"; 
   string working_file=working_folder+Files;
   
   if (FileIsExist(Files,working_folder))
   {
     int h=FileOpen(Files,FILE_READ|FILE_WRITE|FILE_ANSI|FILE_TXT);
     if(h==INVALID_HANDLE)
     {
      Alert("Error opening file");
      return;
     }
     else
     {
       FileSeek(h,0,SEEK_END); 
       FileWriteString(h,str);
       FileClose(h);
       Alert("Done");
     }
   }
   else
   {
     create_new_file_record(date,array);
   }
   

}

void data_handler::create_new_file_record(datetime date, double &array[])
{
    int New=FileOpen(Files,FILE_WRITE|FILE_ANSI|FILE_TXT);
    FileClose(New);
    record(date, array);
    
}

bool data_handler::ReadFileToArrayCSV(string FileName,SLine & Lines[])
{
   ResetLastError();
   int h=FileOpen(FileName,FILE_READ|FILE_ANSI|FILE_CSV,";");  //different, do not touch
   if(h==INVALID_HANDLE){
      int ErrNum=GetLastError();
      printf("Error opening file %s # %i",FileName,ErrNum);
      return(false);
   }   
   int lcnt=0; // variable for calculating lines 
   int fcnt=0; // variable for calculating line fields    
   while(!FileIsEnding(h)){
      string str=FileReadString(h);
      // new line (new element of the structure array)
      if(lcnt>=ArraySize(Lines)){ // structure array completely filled
         ArrayResize(Lines,ArraySize(Lines)+1024); // increase the array size by 1024 elements
      }
      ArrayResize(Lines[lcnt].field,64);// change the array size in the structure
      Lines[lcnt].field[0]=str; // assign the first field value
      // start reading other fields in the line
      fcnt=1; // till one element in the line array is occupied
         while(!FileIsLineEnding(h)){ // read the rest of fields in the line
            str=FileReadString(h);
            if(fcnt>=ArraySize(Lines[lcnt].field)){ // field array is completely filled
               ArrayResize(Lines[lcnt].field,ArraySize(Lines[lcnt].field)+64); // increase the array size by 64 elements
            }     
            Lines[lcnt].field[fcnt]=str; // assign the value of the next field
            fcnt++; // increase the line counter
         }
      ArrayResize(Lines[lcnt].field,fcnt); // change the size of the field array according to the actual number of fields
      lcnt++; // increase the line counter
   }
   ArrayResize(Lines,lcnt); // change the array of structures (lines) according to the actual number of lines
   FileClose(h);
   return(true);
}

double data_handler::fetch_data(int input_line, int input_field)
{
   SLine line[];

   if(!ReadFileToArrayCSV(Files,line)){
      Alert("Error Fetching Data, see the \"Experts\ tab for details");
   }
   
   int total_line = ArraySize(line);
   return(line[input_line].field[input_field]);
   
}

bool data_handler::pattern_matcher(double percentage, double &check[])
{
   SLine line[];
   ZeroMemory(count);
   int field_size = ArraySize(check);
   if(!ReadFileToArrayCSV(Files,line)){
      Alert("Error Initialize Matching Pattern, see the \"Experts\ tab for details");
      return(false);
   }
   int total_line = ArraySize(line);
   //Alert (total_line);
      for(int i=0;i<ArraySize(line)-1;i++)
      {
         for(int j=0;j<field_size;j++)  //use the smaller data column as loop to prevent array out of range issue
         {
            //Alert("Line is "+ i + " Column " +j + " is "+line[i].field[j]);
            //Alert("Line is "+ i + " Try Column " +j + " is "+check[j]);
            double record = line[i].field[j+1];
            double check  = check[j];
            //Alert ("In Line "+i+" Record is "+record+" Check is "+check);
            //Alert(MathAbs(check-record));
            
            if (record!=0)
            {
               if (MathAbs(check-record)/MathAbs(record)*100<100-percentage)
               {
                 //Alert ("Counted");
                 count++;
               }
            }
         }
         if (count>field_size*percentage/100)
         {
              //Alert("Matched Count Is " +count+" In the line " +i); //get the line value here
              vote_line=i;
              total_field_size = ArraySize(line[vote_line].field);
              return(true);
          }
         //Alert("---"+field_size);
      } 
   
   
 return(false);
}


datetime data_handler::get_latest_date ()
{
   SLine line[];

   if(!ReadFileToArrayCSV(Files,line)){
      return(0);
      Alert("Error Getting Last Date, see the \"Experts\ tab for details");
   }
   else{
      //Alert("=== Start ==="+ArraySize(line));  
     // datetime date = line[].field[ArraySize(field)];
       int total_line = ArraySize(line);
       //Alert("=== Start ===");  
       for(int i=total_line-1; i>0; i--)
       {
         return(StringToTime(line[i].field[0]));
         break;
       } 
         //Alert("---");
       
      
      
   }
   return(0);
}

void data_handler::vote(int input_line, int input_vote) //Input vote : 1 is buy, 2 is sell, 3 is loss  ***For the input line, is start count from 0, meaning 1 = Line number 2 count from the top
{
    
    read_vote(input_line); //read the vote and update as global variables
    
    //vote into global variable
    if (input_vote==1)
    {vote_buy+=1;}
    if (input_vote==2)
    {vote_sell+=1;}
    if (input_vote==3)
    {vote_loss+=1;}
    
    //rewrite the vote into csv
    rewrite_vote(input_line);
    
}

void data_handler::read_vote(int input_line)
{
   SLine line[];
   ZeroMemory(line);
   if(!ReadFileToArrayCSV(Files,line))
   {
      Alert("Error Reading Vote, see the \"Experts\ tab for details");
   }
   else
   {
       int hold [];
       int total_field = ArraySize(line[input_line].field);
       
       vote_buy  = line[input_line].field[total_field-3];
       vote_sell = line[input_line].field[total_field-2];
       vote_loss = line[input_line].field[total_field-1]; 
       
       
       preprocessing_vote(line[input_line].field);
   }
   
   
   //return(0);
    
}

void data_handler::preprocessing_vote(string &field[])
{
   string str="";
   int size=ArraySize(field);
   if(size>0)
   {
      str=field[0];
      for(int i=1;i<size-3;i++)
      {
         str=str+";"+field[i]; // merge fields using a separator
      }
      preprocessing_string=str;
   }
}

void data_handler::rewrite_vote(int input_line)
{
   int h=FileOpen(Files,FILE_READ|FILE_ANSI|FILE_TXT);
   string tmpName=TmpFileName(Files_Name,"txt");
   int tmph=FileOpen(tmpName,FILE_WRITE|FILE_ANSI|FILE_TXT);
   
   int cnt=-1;
   while(!FileIsEnding(h)){
      cnt++;
      string str=FileReadString(h);
      if(cnt==input_line){
         // replace the line
         if (preprocessing_string !="") //to prevent empty string wrote
         {
             FileWrite(tmph,preprocessing_string+";"+vote_buy+";"+vote_sell+";"+vote_loss);
             //Alert("I am here");
         }
      }
      else{
         // rewrite the line with no changes
         FileWrite(tmph,str);
      }
   }
   FileClose(tmph);
   FileClose(h);
   
   FileDelete(Files);
   FileMove(tmpName,0,Files,FILE_REWRITE);
   

}

string data_handler::TmpFileName(string Name,string Ext){
   string fn=Name+"."+Ext; // forming name
   int n=0;
   while(FileIsExist(fn)){ // if the file exists
      n++;
      fn=Name+IntegerToString(n)+"."+Ext; // add a number to the name
   }
   return(fn);
}
 
