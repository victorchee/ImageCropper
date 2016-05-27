//
//  ImageCropperController.h
//  ImageCropper
//
//  Created by Victor Chee on 16/5/26.
//  Copyright © 2016年 VictorChee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImageCropperControllerDelegate;

@interface ImageCropperController : UIViewController

@property (nonatomic, weak) id<ImageCropperControllerDelegate> delegate;
@property (nonatomic, weak) UIImage *image;

- (instancetype)initWithImage:(UIImage *)image;

@end


@protocol ImageCropperControllerDelegate <NSObject>

@optional
- (void)imageCropperController:(ImageCropperController *)cropper didFinishCropperImage:(UIImage *)image;
- (void)imageCropperControllerDidCancel:(ImageCropperController *)cropper;

@end
