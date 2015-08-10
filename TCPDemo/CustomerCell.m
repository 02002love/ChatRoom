//
//  CustomerCell.m
//  ChatRoom-03
//
//  Created by JinWei on 15/7/22.
//  Copyright (c) 2015年 SongJinWei. All rights reserved.
//

#import "CustomerCell.h"

@implementation CustomerCell
{
    
    UIImageView * _headView;
    UIImageView * _bubbleView;
    UILabel * _messageLabel;
    CGFloat screenWidth;
    CGFloat screenHight;
    CGFloat space;
    
}



-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        screenWidth = [UIScreen mainScreen].bounds.size.width;
        screenHight = [UIScreen mainScreen].bounds.size.height;
        space = 10;
        _headView = [[UIImageView alloc]init];
        _headView.image = [UIImage imageNamed:@"4.jpg"];
        _headView.layer.cornerRadius =20;
        _headView.layer.masksToBounds = YES;
        [self.contentView addSubview:_headView];
        
        _bubbleView = [[UIImageView alloc]init];

        _messageLabel = [[UILabel alloc]init];
        _messageLabel.font = [UIFont systemFontOfSize:14];
        _messageLabel.numberOfLines = 0;
        [_bubbleView addSubview:_messageLabel];
        
        
        
        
    }
    
    
    return self;
}

-(void)config:(NSDictionary * )dict{
    
    
    if ([dict[@"userIdentifacton"] boolValue]) {
        UIImage * image = [UIImage imageNamed:@"fcl_chat_me.png"];
        _bubbleView.image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:28];
        [self.contentView addSubview:_bubbleView];
        _headView.frame = CGRectMake(screenWidth-40-space, space, 40, 40);

        NSString * message = dict[@"message"];
        CGSize  size = [message boundingRectWithSize:CGSizeMake(screenWidth*0.5+10, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil].size;
        _bubbleView.frame =CGRectMake(screenWidth - 2*space -40-size.width-2*space,space, size.width+2*space, size.height+2*space);
        _messageLabel.text = message;
        _messageLabel.frame = CGRectMake(space, space, size.width,size.height);
        
        
    }else{
        
        UIImage * image = [UIImage imageNamed:@"fcl_chat_others"];
        _bubbleView.image = [image stretchableImageWithLeftCapWidth:10 topCapHeight:28];
        [self.contentView addSubview:_bubbleView];
        
        _headView.frame = CGRectMake(space, space, 40, 40);
        
        NSString * message = dict[@"message"];
        CGSize  size = [message boundingRectWithSize:CGSizeMake(screenWidth*0.5+10, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:nil].size;
        _bubbleView.frame =CGRectMake(2*space+40,space, size.width+2*space, size.height+2*space);
        _messageLabel.text = message;
        _messageLabel.frame = CGRectMake(space, space, size.width,size.height);
        
        
    }
    
}


- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
