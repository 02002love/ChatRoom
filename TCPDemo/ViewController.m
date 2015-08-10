//
//  ViewController.m
//  TCPDemo
//
//  Created by JinWei on 15/8/5.
//  Copyright (c) 2015年 SongJinWei. All rights reserved.
//

#import "ViewController.h"
#import "AsyncSocket.h"
#import "FMDatabase.h"
#import "CustomerCell.h"


@interface ViewController ()<AsyncSocketDelegate,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
{
    //TCP采用双工传输
    AsyncSocket * send;
    AsyncSocket * server;
    UITextField * textLa;
    UILabel * message;
    UITableView * _tableView;
    FMDatabase * fm;
    
}
//保存与我链接的 Socket
@property (nonatomic,strong)NSMutableArray * messageArray;
@property (nonatomic,strong)NSMutableArray * dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.messageArray = [NSMutableArray array];
    [self createSocket];
    
       self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"14.jpg"]];
    
    fm = [[FMDatabase alloc]initWithPath:[NSString stringWithFormat:@"%@/Documents/data.db",NSHomeDirectory()]];
    NSLog(@"%@",[NSString stringWithFormat:@"%@/Documents/data.db",NSHomeDirectory()]);
    if ([fm open]) {
        NSLog(@"创建成功");
        BOOL isSucceed = [fm executeUpdate:@"create table messageList (name,message,time,userIdentifacton)"];
        if (isSucceed) {
            NSLog(@"创建表成功");
        }else {
            
            NSLog(@"创建表失败");
        }
    }
    
    
    FMResultSet * result = [fm executeQuery:@"select * from messageList"];
    while (result.next) {
        NSDictionary * res =@{@"name":[result stringForColumn:@"name"],@"message":[result stringForColumn:@"message"],@"time":[result stringForColumn:@"time"],@"userIdentifacton":[result stringForColumn:@"userIdentifacton"]};
        
        [self.messageArray addObject:res];
    }
    
    
    
    [self createTableView];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = 0;

    [[NSNotificationCenter defaultCenter ]addObserver:self selector:@selector(keyShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter ]addObserver:self selector:@selector(keyHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter ]addObserver:self selector:@selector(valueChanged:) name:UITextFieldTextDidChangeNotification object:nil];
    
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

-(void)keyShow:(NSNotification *)noti{
    
    float height = [[noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size.height;
    _tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-height-44);
    if (self.messageArray.count) {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArray.count -1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    textLa.frame = CGRectMake(0, self.view.bounds.size.height-height-44, self.view.bounds.size.width, 44);
//    textLa.
}


-(void)keyHidden:(NSNotification *)noti{
    
    
    _tableView.frame = CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.height-44);
    textLa .frame = CGRectMake(0, self.view.bounds.size.height-44, self.view.bounds.size.width, 44);
    
}

-(void)valueChanged:(NSNotification *)noti{
    

    CGSize  size = [textLa.text boundingRectWithSize:CGSizeMake(self.view.bounds.size.width*0.5+10, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil].size;
    
//    textLa.frame.size.height = 5.5f;
    
    
    
//    NSLog(@"%@",noti.userInfo);
    if (size.height <44) {
        textLa.frame = CGRectMake(textLa.frame.origin.x,textLa.frame.origin.y, textLa.frame.size.width, 44);
    }else{
        textLa.frame = CGRectMake(textLa.frame.origin.x,textLa.frame.origin.y, textLa.frame.size.width, size.height);
    }
}
#pragma mark  创建TableView
-(void)createTableView{
    
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-44) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource =self;
    [self.view addSubview:_tableView];
    
    textLa = [[UITextField alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width,44)];
    if (self.messageArray.count >0) {
         [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArray.count -1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    textLa.delegate =self;
    textLa.backgroundColor =[UIColor grayColor];
    textLa.returnKeyType =UIReturnKeySend;
    textLa.placeholder = @"输入你想说的话";
    textLa.adjustsFontSizeToFitWidth = YES;
//    textLa.alignmentRectInsets =  UIEdgeInsetsMake(0, 0, 0, 0);
    textLa.textAlignment = UITextAlignmentLeft;
    
    //内容的垂直对齐方式  UITextField继承自UIControl,此类中有一个属性contentVerticalAlignment
    textLa.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.view addSubview:textLa];
    
    
    
}

#pragma mark  uitextfield代理

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    if (textLa.text.length==0) {
        return YES;
    }
//    if (textField.text.length>0) {
//        NSDictionary * dict = @{@"message":textField.text,@"my":@"1"};
//        [self.dataArray addObject:dict];
//        [_tableView reloadData];
//        
//        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//        
//        
//    }

    //发送消息
    //判断是否链接
    if (![send isConnected]) {
        [send connectToHost:@"10.0.162.14" onPort:5678 error:nil];
    }
    //    组装 message
    NSDate * newdate = [NSDate date];
    //格式化时间
    NSDateFormatter * fomatter1 = [[NSDateFormatter alloc]init];
    [fomatter1 setDateFormat:@"yyyy-MM-dd hh-mm-ss"];
    //如果是今天 把日期去掉
    
    NSString * strDate = [fomatter1 stringFromDate:newdate];
    
    NSString * message1= [NSString stringWithFormat:@"蒙奇桑说:%@:%@",textLa.text,strDate];
    
    
    [send writeData:[message1 dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:100];
    
    NSDictionary * dict = @{@"name":@"蒙奇桑",@"message":textLa.text,@"time":strDate,@"userIdentifacton":@"1"};
    
    BOOL isSucceed = [fm executeUpdate:@"insert into messageList values (?,?,?,?)",@"蒙奇桑",textLa.text,strDate,@"1"];
    
    if (isSucceed) {
        NSLog(@"自己插入成功");
    }
    [self.messageArray addObject:dict];
    
    [_tableView reloadData];
    
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    textLa.text =nil;
    
    
    return  YES;
}

#pragma mark  tabelView代理方法
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return   self.messageArray.count;
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * ID =@"cellId";
    CustomerCell * cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[CustomerCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    //    数据源的设计  self.messageArray 中每个数据源是字典  记录 用户名 信息内容 时间
//    cell.textLabel.text = [NSString stringWithFormat:@"%@  %@  %@",self.messageArray[indexPath.row][@"name"],self.messageArray[indexPath.row][@"message"],self.messageArray[indexPath.row][@"time"]];
    [cell config:self.messageArray[indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(CGFloat )tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString * string  = self.messageArray[indexPath.row][@"message"];
    
    return [string boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width*0.5+10, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil].size.height+40;
    
    
    
}



-(void)createSocket{
    //创建接收端
    server = [[AsyncSocket alloc]initWithDelegate:self];
    //绑定本机端口号  0~65535之间 用于接收数据  与别人发送给我的是端口要保持一致 是由服务器和客户端之间协商定制  一般是5000以上的端口   0-5000一般是系统的端口  但是还有一些常用的不要占用 如8080
    
    [server acceptOnPort:5678 error:nil];
    
    //持续接收数据   -1 表示极大数  表示一直链接
    [server readDataWithTimeout:-1 tag:100   ];
    
    send = [[AsyncSocket alloc]initWithDelegate:self];
    
    
    
    
    
}

#pragma mark  socket代理

//接收到新的链接
-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket{
    if (self.dataArray ==nil) {
        self.dataArray = [NSMutableArray array];
    }
    //保存新的连接
    [self.dataArray addObject:newSocket];
    
    //当调用完成时候  服务端已经停止了监听  所以我们需服务端继续监听
    [newSocket readDataWithTimeout:-1 tag:100];
    
}
//已经链接
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    
    
}

//收到信息
-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    //当我们收到消息时 依然需要持续保持监听
    [sock readDataWithTimeout:-1 tag:100];
    NSString * str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    //规定:冒号是分割条件   第一个数据是用户名  第二个是发送的内容  第三个是时间
    NSLog(@"%@+++++++++++",str);
    NSArray * array = [str componentsSeparatedByString:@":"];
    if (array.count ==3) {
        NSDictionary * dict = @{@"username":array[0],@"message":array[1],@"time":array[2]};
        
        BOOL isSucceed = [fm executeUpdate:@"insert into messageList values (?,?,?,?)",array[0],array[1],array[2],@"0"];
        
        if (isSucceed) {
            NSLog(@"他人插入成功");
        }
//        [self.messageArray addObject:dict];
        [self.messageArray addObject:dict];
    }
    
    [_tableView reloadData];
    //产生位置偏移
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messageArray.count -1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
}

//发送信息
-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"发送完成");
    
    
}


//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
////发送消息
//    //判断是否链接
//    if (![send isConnected]) {
//        [send connectToHost:@"10.0.162.131" onPort:5678 error:nil];
//    }
//    //要发送的消息
////    NSString * message = @"1⃣️5⃣️4⃣️3⃣️2⃣️6⃣️7⃣️8⃣️6⃣️3⃣️3⃣️";
//
//
//    [send writeData:[textLa.text dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:100];
//    textLa.text =nil;
//
//}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
