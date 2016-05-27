//
//  ImageCropperController.m
//  ImageCropper
//
//  Created by Victor Chee on 16/5/26.
//  Copyright © 2016年 VictorChee. All rights reserved.
//

#import "ImageCropperController.h"

@interface ImageCropperController () {
    UIImageView *originImageView;
    UIView *overlayView;
    UIView *cropperView;
}

@end

@implementation ImageCropperController

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super init]) {
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    UILayoutGuide *margin = self.view.layoutMarginsGuide;
    
    originImageView = [[UIImageView alloc] initWithImage:self.image];
    originImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:originImageView];
    
    originImageView.translatesAutoresizingMaskIntoConstraints = NO;
    CGSize size = self.image.size;
    if (size.width > CGRectGetWidth(self.view.frame) || size.height > CGRectGetHeight(self.view.frame)) {
        CGFloat scale = 0;
        if (size.width > size.height) {
            scale = CGRectGetWidth(self.view.frame)/size.width;
        } else {
            scale = CGRectGetHeight(self.view.frame)/size.height;
        }
        size = CGSizeMake(size.width*scale, size.height*scale);
    }
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:originImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:size.width]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:originImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:size.height]];
    [originImageView.centerXAnchor constraintEqualToAnchor:margin.centerXAnchor].active = YES;
    [originImageView.centerYAnchor constraintEqualToAnchor:margin.centerYAnchor].active = YES;
    
    overlayView = [[UIView alloc] init];
    overlayView.userInteractionEnabled = NO;
    overlayView.backgroundColor = [UIColor blackColor];
    overlayView.alpha = 0.5;
    [self.view addSubview:overlayView];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [overlayView.leadingAnchor constraintEqualToAnchor:margin.leadingAnchor constant:-20].active = YES;
    [overlayView.trailingAnchor constraintEqualToAnchor:margin.trailingAnchor constant:20].active = YES;
    [overlayView.topAnchor constraintEqualToAnchor:margin.topAnchor].active = YES;
    [overlayView.bottomAnchor constraintEqualToAnchor:margin.bottomAnchor].active = YES;
    
    cropperView = [[UIView alloc] init];
    cropperView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    cropperView.layer.borderWidth = 1.0;
    cropperView.userInteractionEnabled = NO;
    [self.view addSubview:cropperView];
    cropperView.translatesAutoresizingMaskIntoConstraints = NO;
    [cropperView.centerXAnchor constraintEqualToAnchor:margin.centerXAnchor].active = YES;
    [cropperView.centerYAnchor constraintEqualToAnchor:margin.centerYAnchor].active = YES;
    [cropperView.widthAnchor constraintEqualToAnchor:cropperView.heightAnchor].active = YES;
    [cropperView.leadingAnchor constraintEqualToAnchor:margin.leadingAnchor constant:-20].active = YES;
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.view addGestureRecognizer:pinchGestureRecognizer];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.view addGestureRecognizer:panGestureRecognizer];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [self.view addSubview:toolbar];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [toolbar.leadingAnchor constraintEqualToAnchor:margin.leadingAnchor constant:-20].active = YES;
    [toolbar.trailingAnchor constraintEqualToAnchor:margin.trailingAnchor constant:20].active = YES;
    [toolbar.bottomAnchor constraintEqualToAnchor:margin.bottomAnchor].active = YES;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss:)];
    UIBarButtonItem *rotateButton = [[UIBarButtonItem alloc] initWithTitle:@"Rotate" style:UIBarButtonItemStylePlain target:self action:@selector(rotate:)];
    UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(confirm:)];
    toolbar.items = @[cancelButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], rotateButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], confirmButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self clipOverlay];
    
    [self fixImageViewSize];
    [self fixImageViewPosition];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)pinch:(UIPinchGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged) {
        originImageView.transform = CGAffineTransformScale(originImageView.transform, sender.scale, sender.scale);
        sender.scale = 1;
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [self fixImageViewSize];
    }
}

- (void)fixImageViewSize {
    CGRect cropperFrame = cropperView.frame;
    CGRect imageFrame = originImageView.frame;
    if (CGRectGetWidth(imageFrame) < CGRectGetWidth(cropperFrame) || CGRectGetHeight(imageFrame) < CGRectGetHeight(cropperFrame)) {
        CGFloat scale = 0;
        if (CGRectGetWidth(imageFrame) < CGRectGetHeight(imageFrame)) {
            scale = CGRectGetWidth(cropperFrame) / CGRectGetWidth(imageFrame);
        } else {
            scale = CGRectGetHeight(cropperFrame) / CGRectGetHeight(imageFrame);
        }
        CGRect sugguestRect = imageFrame;
        sugguestRect.size.width = CGRectGetWidth(imageFrame) * scale;
        sugguestRect.size.height = CGRectGetHeight(imageFrame) * scale;
        sugguestRect.origin.x = CGRectGetMidX(cropperFrame) - sugguestRect.size.width/2.0;
        sugguestRect.origin.y = CGRectGetMidY(cropperFrame) - sugguestRect.size.height/2.0;
        [UIView animateWithDuration:0.25 animations:^{
            originImageView.frame = sugguestRect;
        }];
    }
}

- (void)pan:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [sender translationInView:originImageView.superview];
        originImageView.center = CGPointMake(originImageView.center.x + translation.x, originImageView.center.y + translation.y);
        [sender setTranslation:CGPointZero inView:originImageView.superview];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        [self fixImageViewPosition];
    }
}

- (void)fixImageViewPosition {
    CGRect cropperFrame = cropperView.frame;
    CGRect imageFrame = originImageView.frame;
    CGRect sugguestRect = imageFrame;
    if (CGRectGetMinX(imageFrame) > CGRectGetMinX(cropperFrame)) {
        sugguestRect.origin.x = CGRectGetMinX(cropperFrame);
    }
    if (CGRectGetMinY(imageFrame) > CGRectGetMinY(cropperFrame)) {
        sugguestRect.origin.y = CGRectGetMinY(cropperFrame);
    }
    if (CGRectGetMaxX(imageFrame) < CGRectGetMaxX(cropperFrame)) {
        sugguestRect.origin.x = CGRectGetMaxX(cropperFrame) - CGRectGetWidth(imageFrame);
    }
    if (CGRectGetMaxY(imageFrame) < CGRectGetMaxY(cropperFrame)) {
        sugguestRect.origin.y = CGRectGetMaxY(cropperFrame) - CGRectGetHeight(imageFrame);
    }
    [UIView animateWithDuration:0.25 animations:^{
        originImageView.frame = sugguestRect;
    }];
}

- (void)rotate:(UIBarButtonItem *)sender {
    originImageView.transform = CGAffineTransformRotate(originImageView.transform, M_PI_2);
    [self fixImageViewPosition];
    [self fixImageViewSize];
}

- (void)dismiss:(UIBarButtonItem *)sender {
    if ([self.delegate respondsToSelector:@selector(imageCropperControllerDidCancel:)]) {
        [self.delegate imageCropperControllerDidCancel:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)confirm:(UIBarButtonItem *)sender {
    if ([self.delegate respondsToSelector:@selector(imageCropperController:didFinishCropperImage:)]) {
        UIImage *cropperImage = [self captureView:self.view inRect:cropperView.frame];
        [self.delegate imageCropperController:self didFinishCropperImage:cropperImage];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)clipOverlay {
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    // 四周遮罩留中间
    CGPathAddRect(path, nil, CGRectMake(0, 0, CGRectGetMinX(cropperView.frame), CGRectGetHeight(overlayView.frame)));
    CGPathAddRect(path, nil, CGRectMake(CGRectGetMaxX(cropperView.frame), 0, CGRectGetWidth(overlayView.frame)-CGRectGetMaxX(cropperView.frame), CGRectGetHeight(overlayView.frame)));
    CGPathAddRect(path, nil, CGRectMake(0, 0, CGRectGetWidth(overlayView.frame), CGRectGetMinY(cropperView.frame)));
    CGPathAddRect(path, nil, CGRectMake(0, CGRectGetMaxY(cropperView.frame), CGRectGetWidth(overlayView.frame), CGRectGetHeight(overlayView.frame)-CGRectGetMaxY(cropperView.frame)));
    maskLayer.path = path;
    CGPathRelease(path);
    
    overlayView.layer.mask = maskLayer;
}

- (UIImage *)captureView:(UIView *)view inRect:(CGRect)rect {
    if (!view || CGRectEqualToRect(rect, CGRectZero)) {
        return nil;
    }
    rect = CGRectInset(rect, 5, 5); // 解决黑边问题
    UIGraphicsBeginImageContextWithOptions(rect.size, view.opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
