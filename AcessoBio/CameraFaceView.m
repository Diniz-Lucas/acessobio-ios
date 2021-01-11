//
//  CameraFaceView.m
//  CaptureAcesso
//
//  Created by Matheus Domingos on 10/05/20.
//  Copyright © 2020 Matheus  domingos. All rights reserved.
//

#import "CameraFaceView.h"

#import <sys/utsname.h> // import it in your header or implementation file.
#import "ValidateLiveness.h"


float topOffsetPercent_CameraFace = 30.0f;
float sizeBetweenTopAndBottomPercent_CameraFace = 50.0f;
float marginOfSides_CameraFace = 80.0f;

@interface CameraFaceView ()

@end

@implementation CameraFaceView


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    isSmillingUpponEnter = YES;
    arrLeftEyeOpenProbability = [NSMutableArray new];
    
    [self registerNotifications];
    
    countDown = 1;
    
    [self setOffsetTopPercent:30.0f];
    [self setSizePercentBetweenTopAndBottom:20.0f];
    
    isSelfie = YES;
    [self setupCamera:isSelfie];
    [self startCamera];
    
    
    // High-accuracy landmark detection and face classification
    FIRVisionFaceDetectorOptions *options = [[FIRVisionFaceDetectorOptions alloc] init];
    options.performanceMode = FIRVisionFaceDetectorPerformanceModeAccurate;
    options.landmarkMode = FIRVisionFaceDetectorLandmarkModeAll;
    options.trackingEnabled = YES;
    options.minFaceSize = 0.1;
    options.classificationMode = FIRVisionFaceDetectorClassificationModeAll;
    
    // Initialize the face detector.
    FIRVision *vision = [FIRVision vision];
    self.faceDetector = [vision faceDetectorWithOptions:options];
    
    [self.btTakePic setHidden:NO];
    
    [self initVariables];
    
    [self initialActionOfChangeState:NO];
    [self addFullBrightnessToScreen];
    
    
}

- (void)viewDidDisappear:(BOOL)animated {
    
    
}

-(void)viewWillAppear:(BOOL)animated {
    
}

#pragma mark - Close

- (void)addCloseButton {
    
    btClose = [[UIButton alloc]initWithFrame:CGRectMake(7, 20, 70, 70)];
    [btClose setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
    [btClose addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btClose];
    
}

- (void)close{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Init variables

-(void)initVariables {
    
    resultFaceDetectBehavior = 0; // 1 = Face Match / 2 = Both substandard / 3 = Not match
    resultFaceDetect = 0; // 1 = Face Match / 2 = Both substandard / 3 = Not match
    
    base64ToUsage = @"";
    
    facesNoMatchInFaceDetect = NO;
    
    SESSION = 0;
    
    TimeSessionFirst = 0;
    TimeSessionSecond = 0;
    TimeSessionThird = 0;
    
    isRequestWebService = NO;
    
    isDoneProcess = NO;
    
}


#pragma mark - Flash

- (void)fireFlash {
    
    if(vFlash == nil) {
        
        
        vFlash= [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        [vFlash setBackgroundColor:[UIColor whiteColor]];
        [vFlash setAlpha:0.9];
        
        
        spinFlash = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        if (@available(iOS 13.0, *)) {
            [spinFlash setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleLarge];
        } else {
            // Fallback on earlier versions
            [spinFlash setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
            
        }
        [spinFlash setColor:[UIColor darkGrayColor]];
        spinFlash.center = self.view.center;
        [spinFlash startAnimating];
        
//        HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
//        HUD.indicatorView = [[JGProgressHUDPieIndicatorView alloc] init]; //Or JGProgressHUDRingIndicatorView
//        HUD.progress = 0.8f;
//        HUD.textLabel.text = @"Aguarde...";
//        [HUD showInView:vFlash];
        
        [self.view addSubview:vFlash];
        
    }
    
}

- (void)removeFlash {
    
//    if(HUD != nil) {
//        [HUD dismiss];
//        HUD = nil;
//    }
    
    // [spinFlash stopAnimating];
    //   [spinFlash removeFromSuperview];
    [vFlash removeFromSuperview];
    vFlash = nil;
    spinFlash = nil;
}

#pragma mark - Adjust Brightness Of Screen

- (void)addFullBrightnessToScreen {
    [UIScreen mainScreen].brightness = 1.0;
}

- (void)setNewValuesToParamsLiveness {
    marginOfSides_CameraFace = 60.0f;
}


- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            /* start special animation */
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            /* start special animation */
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            /* start special animation */
            
            [self showRed];
            break;
            
        case UIDeviceOrientationLandscapeRight:
            
            [self showRed];
            break;
            
        default:
            break;
    };
}


- (FIRVisionDetectorImageOrientation)
imageOrientationFromDeviceOrientation:(UIDeviceOrientation)deviceOrientation
cameraPosition:(AVCaptureDevicePosition)cameraPosition {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            if (cameraPosition == AVCaptureDevicePositionFront) {
                return FIRVisionDetectorImageOrientationLeftTop;
            } else {
                return FIRVisionDetectorImageOrientationRightTop;
            }
        case UIDeviceOrientationLandscapeLeft:
            if (cameraPosition == AVCaptureDevicePositionFront) {
                return FIRVisionDetectorImageOrientationBottomLeft;
            } else {
                return FIRVisionDetectorImageOrientationTopLeft;
            }
        case UIDeviceOrientationPortraitUpsideDown:
            if (cameraPosition == AVCaptureDevicePositionFront) {
                return FIRVisionDetectorImageOrientationRightBottom;
            } else {
                return FIRVisionDetectorImageOrientationLeftBottom;
            }
        case UIDeviceOrientationLandscapeRight:
            if (cameraPosition == AVCaptureDevicePositionFront) {
                return FIRVisionDetectorImageOrientationTopRight;
            } else {
                return FIRVisionDetectorImageOrientationBottomRight;
            }
        default:
            return FIRVisionDetectorImageOrientationTopLeft;
    }
}


- (void)registerNotifications {
    
    // Registrando alteracao de orientacao
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
}


#pragma mark - Setup Hole Transparent

- (void)initHoleView {
    
    [self setParamsRectFaces];
    
    if(vHole != nil) {
        [vHole removeFromSuperview];
    }
    
    [self removeFlash];
    
    self->frameCurrent = frameFaceCenter;
    
    
    UIColor *colorBackground = [UIColor colorWithRed:57.0f/255.0f green:74.0f/255.0f blue:98.0f/255.0f  alpha:0.9f];
    
    if(self.colorBackground != nil) {
        colorBackground = self.colorBackground;
    }
    
    vHole = [[UIViewWithHole alloc] initWithFrame:self.view.frame backgroundColor:colorBackground andTransparentRect:frameFaceCenter cornerRadius:0];
    
    [self.view addSubview:vHole];
    [self addButtonTakePicture:vHole];
    
    // [self addImageAcessoBio];
    
}

- (void)addVHole: (CGRect) rect  {
    
    [self->vHole removeFromSuperview];
    UIColor *colorBackground = [UIColor colorWithRed:57.0f/255.0f green:74.0f/255.0f blue:98.0f/255.0f  alpha:0.9f];
    
    if(self.colorBackground != nil) {
        colorBackground = self.colorBackground;
    }
    
    self->vHole = [[UIViewWithHole alloc] initWithFrame:self.view.frame backgroundColor:colorBackground andTransparentRect:rect cornerRadius:0];
    [self.view addSubview:self->vHole];
    
}

- (void)removeVHole {
    [self->vHole removeFromSuperview];
    [self->vAlert removeFromSuperview];
    [self.view bringSubviewToFront:self->btClose];
}

- (void)changeHoleView: (CGRect) newRect delayInSeconds: (double)delayInSeconds {
    
    if(!CGRectEqualToRect(newRect, CGRectZero)) {
        self->frameCurrent = newRect;
    }
    
    isSuccessAnimated = NO;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self addVHole:newRect];
            [self.view bringSubviewToFront:self->vAlert];
            [self.view bringSubviewToFront:self->btClose];
            [self.view bringSubviewToFront:self->ivAcessoBio];
            [self.view bringSubviewToFront:self.btTakePic];
            
            self->isProccessIA = NO;
            
        });
        
    });
    
}

- (void)setParamsRectFaces {
    
    frameFaceCenter = CGRectMake((SCREEN_WIDTH/2) - 125 ,(SCREEN_HEIGHT/2) - 180, 250, 400);
    frameFaceAway = CGRectMake((SCREEN_WIDTH/2) - 90 ,(SCREEN_HEIGHT/2) - 140, 180, 280);
    frameFaceCloser = CGRectMake((SCREEN_WIDTH/2) - 150 ,(SCREEN_HEIGHT/2) - 250, 300, 500);
    
}

#pragma mark - Setup Camera

- (void) setupCamera:(BOOL) isSelfie {
    [super setupCamera:isSelfie];
    
    
}

- (void) startCamera {
    [self.session startRunning];
}

- (void) stopCamera {
    [self.session stopRunning];
}

- (void)setIsDebug : (BOOL)debug {
    self.debug = debug;
    
    if(self.debug) {
        
        UIButton *btClear = [[UIButton alloc]initWithFrame:CGRectMake(20, SCREEN_HEIGHT - 100 , 80, 50)];
        [btClear setTitle:@"RESET" forState:UIControlStateNormal];
        [btClear.titleLabel setFont:[UIFont fontWithName:@"Avenir-Book" size:14.0]];
        [btClear setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btClear setBackgroundColor:[UIColor blackColor]];
        [btClear addTarget:self action:@selector(clearDots) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btClear];
        
        viewLog = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 150, 160)];
        [viewLog setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:viewLog];
        
        lbLeftEye = [[UILabel alloc]initWithFrame:CGRectMake(10, 20, 150, 20)];
        [lbLeftEye setFont:[UIFont systemFontOfSize:10.0]];
        [lbLeftEye setTextColor: [UIColor blackColor]];
        [lbLeftEye setTag:-1];
        [viewLog addSubview:lbLeftEye];
        
        lbRightEye = [[UILabel alloc]initWithFrame:CGRectMake(10, 40, 150, 20)];
        [lbRightEye setFont:[UIFont systemFontOfSize:10.0]];
        [lbRightEye setTextColor: [UIColor blackColor]];
        [lbRightEye setTag:-1];
        [viewLog addSubview:lbRightEye];
        
        lbNosePosition = [[UILabel alloc]initWithFrame:CGRectMake(10, 60, 150, 20)];
        [lbNosePosition setFont:[UIFont systemFontOfSize:10.0]];
        [lbNosePosition setTextColor: [UIColor blackColor]];
        [lbNosePosition setTag:-1];
        [viewLog addSubview:lbNosePosition];
        
        lbLeftEar = [[UILabel alloc]initWithFrame:CGRectMake(10, 80, 150, 20)];
        [lbLeftEar setFont:[UIFont systemFontOfSize:10.0]];
        [lbLeftEar setTextColor: [UIColor blackColor]];
        [lbLeftEar setTag:-1];
        [viewLog addSubview:lbLeftEar];
        
        lbRightEar = [[UILabel alloc]initWithFrame:CGRectMake(10, 100, 150, 20)];
        [lbRightEar setFont:[UIFont systemFontOfSize:10.0]];
        [lbRightEar setTextColor: [UIColor blackColor]];
        [lbRightEar setTag:-1];
        [viewLog addSubview:lbRightEar];
        
        lbEulerX = [[UILabel alloc]initWithFrame:CGRectMake(10, 120, 150, 20)];
        [lbEulerX setFont:[UIFont systemFontOfSize:10.0]];
        [lbEulerX setTextColor: [UIColor blackColor]];
        [lbEulerX setTag:-1];
        [viewLog addSubview:lbEulerX];
        
        lbSpaceEye = [[UILabel alloc]initWithFrame:CGRectMake(10, 140, 150, 20)];
        [lbSpaceEye setFont:[UIFont systemFontOfSize:10.0]];
        [lbSpaceEye setTextColor: [UIColor blackColor]];
        [lbEulerX setTag:-1];
        [viewLog addSubview:lbSpaceEye];
        
        UIView *v1 = [[UIView alloc]initWithFrame:CGRectMake(0, topOffsetPercent_CameraFace, SCREEN_WIDTH, 2)];
        [v1 setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:v1];
        
        UIView *v2 = [[UIView alloc]initWithFrame:CGRectMake(0, sizeBetweenTopAndBottomPercent_CameraFace, SCREEN_WIDTH, 2)];
        [v2 setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:v2];
        
        UIView *v3 = [[UIView alloc]initWithFrame:CGRectMake(marginOfSides_CameraFace, 0, 2, SCREEN_HEIGHT)];
        [v3 setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:v3];
        
        UIView *v4 = [[UIView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - marginOfSides_CameraFace, 0, 2, SCREEN_HEIGHT)];
        [v4 setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:v4];
        
    }
    
}

- (void)setOffsetTopPercent : (float)percent {
    topOffsetPercent_CameraFace = percent/100 *  SCREEN_HEIGHT;
}

- (void)setSizePercentBetweenTopAndBottom  : (float)percent {
    float pixels = percent/100 *  SCREEN_HEIGHT;
    sizeBetweenTopAndBottomPercent_CameraFace = topOffsetPercent_CameraFace + pixels;
}

- (void)setMarginOfSides: (float)margin {
    marginOfSides_CameraFace = margin;
}

- (void)clearDots {
    for (UIView *view in [self.view subviews]) {
        if(view.tag == - 1) {
            [view removeFromSuperview];
        }
    }
}

- (void)addCircleToPoint : (CGPoint) point color : (UIColor *)color{
    
    CGFloat widht = 10;
    
    CGFloat POINT_X = point.x;
    CGFloat POINT_Y = point.y;
    
    CGRect circleRect = CGRectMake(POINT_X - (widht / 2), POINT_Y - (widht / 2), widht, widht);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIView *circleView = [[UIView alloc] initWithFrame:circleRect];
        circleView.layer.cornerRadius = widht/2;
        circleView.alpha = 0.7;
        circleView.backgroundColor = color;
        circleView.tag = -1;
        [self.view addSubview:circleView];
        
    });
    
}

- (void)addLabelToLog : (CGPoint) point type : (NSString * )type{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([type isEqualToString:@"left_eye"]) {
            [self->lbLeftEye setText:[NSString stringWithFormat:@"Leyft eye - X: %.0f Y: %.0f", point.x, point.y]];
        }else if([type isEqualToString:@"right_eye"]) {
            [self->lbRightEye setText:[NSString stringWithFormat:@"Right eye - X: %.0f Y: %.0f", point.x, point.y]];
        }if([type isEqualToString:@"left_ear"]) {
            [self->lbLeftEar setText:[NSString stringWithFormat:@"Leyft ear - X: %.0f Y: %.0f", point.x, point.y]];
        }else if([type isEqualToString:@"right_ear"]) {
            [self->lbRightEar setText:[NSString stringWithFormat:@"Right ear - X: %.0f Y: %.0f", point.x, point.y]];
        }else if([type isEqualToString:@"euler"]) {
            [self->lbEulerX setText:[NSString stringWithFormat:@"Euler X: %.0f Y: %.0f", point.x, point.y]];
        }else if([type isEqualToString:@"space-eye"]) {
            [self->lbSpaceEye setText:[NSString stringWithFormat:@"Space eye: %.0f", point.x]];
        }else{
            [self->lbNosePosition setText:[NSString stringWithFormat:@"Base nose - X: %.0f Y: %.0f", point.x, point.y]];
        }
        
    });
    
}

- (void) capture {
    
    if(!isDoneProcess) {
        
        if(!self->isProccessIA) {
            
            if(!isTakingPhoto) {
                isTakingPhoto = YES;
                
                
                if(self->isPhotoAwayToCapture) {
                    [self take];
                    
                }else{
                    
                    [self fireFlash];
                    
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self take];
                    });
                    
                }
                
                
            }
            
        }
    }
    
}


- (void)take {
    
    AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            [self.renderLock lock];
            [self.renderLock unlock];
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            UIImage *capturedImage = [[UIImage alloc] initWithData:imageData];
            
            if (self.defaultCamera == AVCaptureDevicePositionFront) {
                capturedImage = [UIImageUtils flipImage:[UIImageUtils imageRotatedByDegrees:capturedImage deg:-90]];
            } else {
                capturedImage = [UIImageUtils imageRotatedByDegrees:capturedImage deg:90];
            }
            
            // [self stopCamera];
            //[self generateHashFromImage:capturedImage];
            
            NSString* base64;
            base64 = [UIImageUtils getBase64Image: capturedImage]; // Utilizar esse base64 para a validação no WebService
            
            if(self->isPhotoAwayToCapture) {
                self->isPhotoAwayToCapture = NO;
                self->isTakingPhoto  = NO;
                self->_base64AwayWithoutSmilling = base64;
                self.imgAwayWithoutSmile = capturedImage;
            }else{
                //Como é assincrono, eu defino como processando a IA e disparo uma action dps de 3 segundos verificando se a thread UI foi liberada. Caso nao, eu libero.
                
                self->isTakingPhoto  = NO;
                self->isProccessIA = YES;
                [self performSelector:@selector(resetVariableProcessIA) withObject:nil afterDelay:3.0];;
                [self actionAfterTakePicture:base64 image:capturedImage];
            }
            
            [self stopCamera];
            
            
        }
    }];
    
}


- (void) addImageAcessoBio {
    if(IS_IPHONE_X || IS_IPHONE_6P){
        ivAcessoBio = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH/2) - 50, SCREEN_HEIGHT - 70, 100, 40)];
        
    }else{
        ivAcessoBio = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH/2) - 50, SCREEN_HEIGHT - 50, 100, 40)];
        
    }
    [ivAcessoBio setImage:[UIImage imageNamed:@"ic_bio"]];
    [ivAcessoBio setContentMode:UIViewContentModeScaleAspectFit];
    [ivAcessoBio setTag:-99];
    [self.view addSubview:ivAcessoBio];
}



-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if(!isDoneProcess) {
        
        FIRVisionImageMetadata *metadata = [[FIRVisionImageMetadata alloc] init];
        AVCaptureDevicePosition cameraPosition =
        AVCaptureDevicePositionBack;  // Set to the capture device you used.
        metadata.orientation =
        [self imageOrientationFromDeviceOrientation:UIDevice.currentDevice.orientation
                                     cameraPosition:cameraPosition];
        
        FIRVisionImage *image = [[FIRVisionImage alloc] initWithBuffer:sampleBuffer];
        image.metadata = metadata;
        
        if(_isEnableSmartCapture) {
            [self.faceDetector
             processImage:image
             completion:^(NSArray<FIRVisionFace *> *_Nullable faces, NSError *_Nullable error) {
                
                if (self->isPopUpShow) {
                    return;
                }
                
                if([faces count] > 0) {
                    
                    if([faces count] == 1) {
                        
                        self->countNoFace = 0;
                        
                        FIRVisionFace *faceFeature = faces[0];
                        
                        FIRVisionFaceLandmark *noseBaseLandmark = [faceFeature landmarkOfType:FIRFaceLandmarkTypeNoseBase];
                        
                        if(noseBaseLandmark != nil) {
                            
                            if(faceFeature.hasLeftEyeOpenProbability || faceFeature.hasRightEyeOpenProbability) {
                                [self->arrLeftEyeOpenProbability addObject:[NSNumber numberWithFloat:faceFeature.leftEyeOpenProbability]];
                            }
                            
                            
                            [self analyzeFaceCenter:faceFeature];
                            
                            
                        }else{
                            //  countNoNose++;
                            //if(countNoNose >= 10)
                            [self showGray];
                        }
                    }
                }else{
                    self->countNoFace++;
                    if(self->countNoFace >= 20)
                        [self showGray];
                    
                }}];
        }
        
    }
    
    if ([self.renderLock tryLock]) {
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        self.latestFrame = image;
        [self.renderLock unlock];
    }
    
    
}
- (void)analyzeFaceCenter  : (FIRVisionFace *)faceFeature{
    
    
    FIRVisionFaceLandmark *leftEyeLandmark = [faceFeature landmarkOfType:FIRFaceLandmarkTypeLeftEye];
    
    CGPoint leftEyePosition = [self pointFromVisionPoint:leftEyeLandmark.position];
    
    FIRVisionFaceLandmark *rightEyeLandmark = [faceFeature landmarkOfType:FIRFaceLandmarkTypeRightEye];
    
    CGPoint rightEyePosition = [self pointFromVisionPoint:rightEyeLandmark.position];
    
    FIRVisionFaceLandmark *leftEarLandmark = [faceFeature landmarkOfType:FIRFaceLandmarkTypeLeftEar];
    
    CGPoint leftEarPosition = [self pointFromVisionPoint:leftEarLandmark.position];
    
    FIRVisionFaceLandmark *rightEarLandmark = [faceFeature landmarkOfType:FIRFaceLandmarkTypeRightEar];
    
    CGPoint rightEarPosition = [self pointFromVisionPoint:rightEarLandmark.position];
    
    FIRVisionFaceLandmark *noseBaseLandmark = [faceFeature landmarkOfType:FIRFaceLandmarkTypeNoseBase];
    
    CGPoint noseBasePosition = [self pointFromVisionPoint:noseBaseLandmark.position];
    
    
    countNoNose = 0;
    
    /*
     - Get poits position at screen.
     */
    
    CGFloat scale = 2;// [UIScreen mainScreen].scale;
    
    // Olhos
    CGFloat X_LEFT_EYE_POINT = SCREEN_WIDTH - (leftEyePosition.x/scale);
    CGFloat Y_LEFT_EYE_POINT = leftEyePosition.y/scale;
    
    CGFloat X_RIGHT_EYE_POINT = SCREEN_WIDTH - (rightEyePosition.x/scale);
    CGFloat Y_RIGHT_EYE_POINT = rightEyePosition.y/scale;
    
    // Orelhas
    CGFloat X_LEFT_EAR_POINT = SCREEN_WIDTH - (leftEarPosition.x/scale);
    CGFloat Y_LEFT_EAR_POINT = leftEarPosition.y/scale;
    
    CGFloat X_RIGHT_EAR_POINT = SCREEN_WIDTH - (rightEarPosition.x/scale);
    CGFloat Y_RIGHT_EAR_POINT = rightEarPosition.y/scale;
    
    // Nariz
    CGFloat X_NOSEBASEPOSITION_POINT = SCREEN_WIDTH - (noseBasePosition.x/scale);
    CGFloat Y_NOSEBASEPOSITION_POINT = noseBasePosition.y/scale;
    
    //Angulo
    CGFloat ANGLE_HORIZONTAL = faceFeature.headEulerAngleY;
    CGFloat ANGLE_VERTICAL = faceFeature.headEulerAngleZ;
    
    /*
     ------
     */
    
    /*
     - Plot points to visually with color on the screen.
     */
    
    
    if(self.debug){
        
        [self addCircleToPoint:CGPointMake(X_LEFT_EYE_POINT, Y_LEFT_EYE_POINT) color:[UIColor redColor]];
        
        [self addCircleToPoint:CGPointMake(X_RIGHT_EAR_POINT, Y_RIGHT_EAR_POINT) color:[UIColor yellowColor]];
        [self addCircleToPoint:CGPointMake(X_LEFT_EAR_POINT, Y_LEFT_EAR_POINT) color:[UIColor yellowColor]];
        
        [self addCircleToPoint:CGPointMake(X_RIGHT_EYE_POINT, Y_RIGHT_EYE_POINT) color:[UIColor blueColor]];
        
        [self addCircleToPoint:CGPointMake(X_NOSEBASEPOSITION_POINT, Y_NOSEBASEPOSITION_POINT) color:[UIColor greenColor]];
        
        
        
        [self addLabelToLog:CGPointMake(X_LEFT_EYE_POINT, Y_LEFT_EYE_POINT) type:@"left_eye"];
        [self addLabelToLog:CGPointMake(X_RIGHT_EYE_POINT, Y_RIGHT_EYE_POINT) type:@"right_eye"];
        
        [self addLabelToLog:CGPointMake(X_LEFT_EAR_POINT, Y_LEFT_EAR_POINT) type:@"left_ear"];
        [self addLabelToLog:CGPointMake(X_RIGHT_EAR_POINT, Y_RIGHT_EAR_POINT) type:@"right_ear"];
        
        [self addLabelToLog:CGPointMake(X_NOSEBASEPOSITION_POINT, Y_NOSEBASEPOSITION_POINT) type:@"nose_base"];
        
        [self addLabelToLog:CGPointMake((fabs(X_LEFT_EYE_POINT - X_RIGHT_EYE_POINT)) * 2, 0) type:@"space-eye"];
        
    }
    
    
    /*
     ------
     */
    
    if(self.debug){
        NSLog(@"X_NOSEBASEPOSITION_POINT %.2f - Y_NOSEBASEPOSITION_POINT %.2f", noseBasePosition.x, noseBasePosition.y);
    }
    
    BOOL hasError = NO;
    NSMutableString *strError = [NSMutableString new];
    
    /*
     - Verify wether face is centralized.
     */
    //if((Y_NOSEBASEPOSITION_POINT > 250  && Y_NOSEBASEPOSITION_POINT < 400) &&
    
    
    if(leftEyeLandmark != nil && rightEyeLandmark != nil)  {
        
        if(self.debug) {
            NSLog(@"ORELHA ESQUERDA: %.2f", X_LEFT_EAR_POINT);
            NSLog(@"FRAME FACE X: %.2f", frameFaceCenter.origin.x);
            NSLog(@"ORELHA DIREITA: %.2f", X_RIGHT_EAR_POINT);
            NSLog(@"FRAME FACE X + W: %.2f", frameFaceCenter.origin.x + frameFaceCenter.size.width);
            NSLog(@"DISTANCIA OLHOS: %.2f", fabs(X_LEFT_EYE_POINT - X_RIGHT_EYE_POINT) * 2);
        }
        
        
        int leftMargin = frameFaceCenter.origin.x;
        int rightMargin = (frameFaceCenter.origin.x + frameFaceCenter.size.width);
        
        
        float minimumDistance = 150;
        if(IS_IPHONE_X || IS_IPHONE_6P) {
            minimumDistance = 150;
        }
        
        
        if(X_RIGHT_EAR_POINT < leftMargin || X_LEFT_EAR_POINT > rightMargin) {
            countTimeAlert ++;
            // [self showRed];
            if(hasError){
                [strError appendString:@" / Put your face away"];
            }else{
                [strError appendString:@"Put your face away"];
            }
            hasError = YES;
            
        }else if(((fabs(X_LEFT_EYE_POINT - X_RIGHT_EYE_POINT)) * 2) < minimumDistance) {
            countTimeAlert ++;
            // [self showRed];
            if(hasError){
                [strError appendString:@" / Bring the face closer"];
            }else{
                [strError appendString:@"Bring the face closer"];
            }
            
            hasError = YES;
            
        }else if((fabs(Y_LEFT_EYE_POINT - Y_RIGHT_EYE_POINT) > 20) || (fabs(Y_RIGHT_EYE_POINT - Y_LEFT_EYE_POINT) > 20)){
            countTimeAlert ++;
            if(hasError){
                [strError appendString:@" / Inclined face"];
            }else{
                [strError appendString:@"Inclined face"];
            }
            hasError = YES;
            
        }
        
    }
    
    
    //[self addLabelToLog:CGPointMake(ANGLE_HORIZONTAL , ANGLE_VERTICAL) type:@"euler"];
    
    if(ANGLE_HORIZONTAL > 20 || ANGLE_HORIZONTAL < -20) {
        countTimeAlert ++;
        //[self showRed];
        if(hasError){
            if(ANGLE_HORIZONTAL > 20) {
                [strError appendString:@" / Turn slightly left"];
            }else if(ANGLE_HORIZONTAL < -20){
                [strError appendString:@" / Turn slightly right"];
            }
        }else{
            if(ANGLE_HORIZONTAL > 20) {
                [strError appendString:@"Turn slightly left"];
            }else if(ANGLE_HORIZONTAL < -20){
                [strError appendString:@"Turn slightly right"];
            }
        }
        hasError = YES;
        
    }
    
    if(hasError) {
        [self showAlert:strError];
        hasError = NO;
    }else{
        [self faceOK]; // Face is centralized.
    }
    
}


- (void)showAlert : (NSString *)alert {
    
    if(countTimeAlert >= 10) {
        
        countTimeAlert = 0;
        isShowAlert = NO;
        
        [self showRed];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            CATransition *animation = [CATransition animation];
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            animation.type = kCATransitionFade;
            animation.duration = 0.75;
            [self->lbMessage.layer addAnimation:animation forKey:@"kCATransitionFade"];
            
            if([alert containsString:@"Bring the face closer"]) {
                [self setMessageStatus:@"Aproxime o rosto"];
            }else if ([alert containsString:@"Put your face away"]){
                [self setMessageStatus:@"Afaste o rosto"];
            }else if ([alert containsString:@"Inclined face"]){
                [self setMessageStatus:@"Deixe seu rosto reto na tela"];
            }else{
                [self setMessageStatus:@"Enquadre o seu rosto"];
            }
            
            
            UIColor *colorLbMessage = [UIColor whiteColor];
            
            if(self.colorTextBoxStatus != nil) {
                colorLbMessage = self.colorTextBoxStatus;
            }
            [self->lbMessage setTextColor:colorLbMessage];
            
            
        });
        
    }
    
}

- (void)showRed{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(self->timerCountDown != nil) {
            [self resetTimer];
        }
        
        [self.btTakePic setAlpha:0.5];
        [self.btTakePic setEnabled:NO];
        
        UIColor *colorBorder  = [UIColor whiteColor];
        if(self.colorSilhoutteError != nil) {
            colorBorder = self.colorSilhoutteError;
        }
        
        self->vHole.shapeLayer.strokeColor = [colorBorder CGColor];
        
        /*
         [self->rectangle setBackgroundColor:[UIColor redColor]];
         [self->rectangleTop setBackgroundColor:[UIColor redColor]];
         [self->rectangleLeft setBackgroundColor:[UIColor redColor]];
         [self->rectangleRight setBackgroundColor:[UIColor redColor]];
         */
    });
    
}


- (void)showGray{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(self->timerCountDown != nil) {
            [self resetTimer];
        }
        
        //        if([UserDefaults getLiveness]) {
        //            [self setMessageStatus:@"Enquadre seu rosto"];
        //            [self->lbMessage setTextColor:[UIColor whiteColor]];
        //        }
        
        
        [self setMessageStatus:@"Enquadre seu rosto"];
        
        
        UIColor *colorBorder  = [UIColor whiteColor];
        if(self.colorSilhoutteNeutral != nil) {
            colorBorder = self.colorSilhoutteNeutral;
        }
        
        self->vHole.shapeLayer.strokeColor = [colorBorder CGColor];
        
        
        [self.btTakePic setAlpha:0.5];
        [self.btTakePic setEnabled:NO];
        /*
         [self->rectangle setBackgroundColor:[UIColor grayColor]];
         [self->rectangleTop setBackgroundColor:[UIColor grayColor]];
         [self->rectangleLeft setBackgroundColor:[UIColor grayColor]];
         [self->rectangleRight setBackgroundColor:[UIColor grayColor]];
         */
    });
    
}

- (void)faceOK{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(self.isEnableAutoCapture) {
            if(!self->isCountDown) {
                [self createTimer];
                self->isCountDown = YES;
            }
        }
        
        if(!self->isProccessIA) {
            
            [self->vAlert setHidden:YES];
            [self setMessageStatus:@"Não se mexa..."];
            
        }
        
        [self.btTakePic setAlpha:1];
        [self.btTakePic setEnabled:YES];
        
        UIColor *colorSuccess = [self getColorGreen];
        
        if(self.colorSilhoutteSuccess != nil) {
            colorSuccess = self.colorSilhoutteSuccess;
        }
        
        self->vHole.shapeLayer.strokeColor = [colorSuccess CGColor];
        
    });
    
}


- (CGPoint)pointFromVisionPoint:(FIRVisionPoint *)visionPoint {
    return CGPointMake(visionPoint.x.floatValue, visionPoint.y.floatValue);
}


#pragma mark - liveness_Session

// Initialize or restart params and variables to the session.
- (void)initSession {
    
    lbMessage.text = @"";
    isResetRunning = NO;
    
    self.base64Center = @"";
    
}

- (void)resetBlinking {
    arrLeftEyeOpenProbability = [NSMutableArray new];
}

- (void)resetSession {
    
    if(!isValidating) {
        
        [self initSession];
        [self initialActionOfChangeState:YES];
        
    }
    
}


- (void)resetTimer {
    [self->timerCountDown invalidate];
    self->countDown = 1.3;
    self->isCountDown = NO;
    self->timerCountDown = nil;
}

- (void)createTimer {
    
    //    if(lStateType != LivenessStateCenterFace) {
    //        countDown = 0;
    //    }
    
    
    self->timerCountDown = [NSTimer scheduledTimerWithTimeInterval:0.8
                                                            target:self
                                                          selector:@selector(countDown)
                                                          userInfo:nil
                                                           repeats:YES];
    
    
}

- (void)countDown {
    
    if(!isShowAlertLiveness) {
        
        
        if(countDown == 1) {
            //                if(!self->isSuccessAnimated) {
            //                    self->isSuccessAnimated = YES;
            //                    [self->vHole startAnimationSuccess];
            //                }
        }
        
        if(countDown == 0) {
            if(!self->isSuccessAnimated) {
                self->isSuccessAnimated = YES;
                // [self->vHole startAnimationSuccess];
            }
            [self resetTimer];
            [self capture];
        }
        
        countDown --;
        
    }
    
    
    
}


- (void)switchCam {
    
    
    if(self.session)
    {
        //Indicate that some changes will be made to the session
        [self.session beginConfiguration];
        
        //Remove existing input
        AVCaptureInput* currentCameraInput = [self.session.inputs objectAtIndex:0];
        [self.session removeInput:currentCameraInput];
        
        //Get new input
        AVCaptureDevice *newCamera = nil;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        else
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
        
        
        
        //Add input to session
        NSError *err = nil;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
        if(!newVideoInput || err)
        {
            NSLog(@"Error creating capture device input: %@", err.localizedDescription);
        }
        else
        {
            [self.session addInput:newVideoInput];
        }
        
        //Commit all the configuration changes at once
        [self.session commitConfiguration];
    }
    
    
}

- (void)actionAfterTakePicture : (NSString *)base64 image:(UIImage *)image {
    
    isValidating = YES;
    
    _base64Center = base64;
    _imgCenter = image;
    
    if(self.isFacesCompareOneToOne) {
        [self facesCompare:self.cpfToFacesCompare base64:base64];
    }else if(self.acessiBioManager.createProcess == nil){
        CameraFaceResult *cameraFaceResult = [CameraFaceResult new];
        [cameraFaceResult setBase64:self->_base64Center];
        [self.acessiBioManager onSuccesCameraFace:cameraFaceResult];
        [self doneProcess];
    }else{
        [self createProcessV3];
    }
    
}


- (void)invalidateAllTimers {
    
    if(timerProcesss != nil) {
        [timerProcesss invalidate];
        timerProcesss = nil;
    }
    
    if(timerToTakeCenterPhoto != nil) {
        [timerToTakeCenterPhoto invalidate];
        timerToTakeCenterPhoto = nil;
    }
    
    if(timerToTakeAwayPhoto != nil) {
        [timerToTakeAwayPhoto invalidate];
        timerToTakeAwayPhoto = nil;
    }
    
    [self invalidateTimerToSmiling];
    
}

- (void)invalidateTimerToSmiling {
    if(timerToSmiling != nil) {
        [timerToSmiling invalidate];
        timerToSmiling = nil;
    }
}

- (void)initialActionOfChangeState : (BOOL)fromReset {
    
    if(!isDoneProcess) {
        
        [self initHoleView];
        [self createViewAlert];
        [self addCloseButton];
        
        if(fromReset) {
            [self popupShow];
        }
        
    }
    
}


- (void)resetVariableProcessIA {
    if(isProccessIA){
        isProccessIA = NO;
    }
}



- (void)createViewAlert {
    
    
    if(popup == nil) {
        vAlert = [[UIView alloc]initWithFrame:CGRectMake(20, (frameFaceCenter.origin.y - 25) , SCREEN_WIDTH - 40, 50)];
        [vAlert setBackgroundColor:[UIColor colorWithRed:24.0f/255.0f green:30.0f/255.0f blue:45.0f/255.0f alpha:1.0]];
        [vAlert setAlpha:1.0f];
        [vAlert.layer setMasksToBounds:YES];
        [vAlert.layer setCornerRadius:10.0];
        [self.view addSubview:vAlert];
        
        //    vAlert.layer.shadowRadius  = 1.5f;
        //    vAlert.layer.shadowColor   = [UIColor colorWithRed:0.f/255.f green:0.f/255.f blue:0.f/255.f alpha:1.f].CGColor;
        //    vAlert.layer.shadowOffset  = CGSizeMake(0.0f, 0.0f);
        //    vAlert.layer.shadowOpacity = 0.5f;
        //    vAlert.layer.masksToBounds = NO;
        //
        //    UIEdgeInsets shadowInsets     = UIEdgeInsetsMake(0, 0, -1.5f, 0);
        //    UIBezierPath *shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(vAlert.bounds, shadowInsets)];
        //    vAlert.layer.shadowPath    = shadowPath.CGPath;
        
        lbMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, vAlert.frame.size.width, 50)];
        [lbMessage setText:@"Enquadre seu rosto"];
        [lbMessage setMinimumScaleFactor:0.5];
        UIColor *colorLbMessage = [UIColor whiteColor];
        
        if(self.colorTextBoxStatus != nil) {
            colorLbMessage = self.colorTextBoxStatus;
        }
        [lbMessage setTextColor:colorLbMessage];
        
        UIColor *colorBackgroundBox = [UIColor colorWithRed:24.0f/255.0f green:30.0f/255.0f blue:45.0f/255.0f alpha:1.0];
        if(self.colorBackgroundBoxStatus != nil) {
            colorBackgroundBox = self.colorBackgroundBoxStatus;
        }
        
        [lbMessage setBackgroundColor:colorBackgroundBox];
        [lbMessage setTextAlignment:NSTextAlignmentCenter];
        [lbMessage setFont:[UIFont boldSystemFontOfSize:17.5]];
        [vAlert addSubview:lbMessage];
        
        
        //   [self startBlinkingLabel:lbMessage];
    }
    
    
    
}

- (void)fireAlert : (NSString *)message {
    
    
}

- (void)setMessageStatus: (NSString *)str {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->popup == nil) {
            [self->vAlert setHidden:NO];
            [self->lbMessage setText:str];
        }else{
            [self->vAlert setHidden:YES];
            [self->lbMessage setText:@""];
        }
    });
    
}

-(void) startBlinkingLabel:(UILabel *)label
{
    label.alpha =1.0f;
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options: UIViewAnimationOptionAutoreverse |UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction |UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        label.alpha = 0.0f;
    }
                     completion:^(BOOL finished){
        if (finished) {
            
        }
    }];
}

-(void) stopBlinkingLabel:(UILabel *)label
{
    // REMOVE ANIMATION
    [label.layer removeAnimationForKey:@"opacity"];
    label.alpha = 1.0f;
}


- (void)forceDoneProcess {
    
    if(!validateFaceDetectOK) {
        [self doneProcess];
    }
    
}

- (void)doneProcess {
    
//    if(HUD != nil) {
//        HUD.progress = 1.0f;
//    }
    
    if(!isDoneProcess){
        isDoneProcess = YES;
        [self stopCamera];
        [self invalidateAllTimers];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

#pragma mark - Create Process v3

- (void)createProcessV3 {
    
    isRequestWebService = YES;
    
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    AFJSONRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
//
//    manager.requestSerializer = serializer;
//    [manager.requestSerializer setValue:self.APIKEY forHTTPHeaderField:@"APIKEY"];
//    [manager.requestSerializer setValue:self.TOKEN forHTTPHeaderField:@"Authorization"];
//
//    NSDictionary *dict = @{
//        @"subject" : @{@"Code": self.acessiBioManager.createProcess.code, @"Name": self.acessiBioManager.createProcess.name},
//        @"onlySelfie" : [NSNumber numberWithBool:YES],
//        @"imagebase64": _base64Center
//    };
//
//    [manager POST:[NSString stringWithFormat:@"%@/services/v3/AcessoService.svc/processes", self.URL] parameters:dict headers:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
//
//        NSDictionary *result = responseObject;
//        NSString * processId = [result valueForKey:@"Id"];
//
//        self->HUD.progress = 0.8f;
//        self->isValidating = NO;
//
//        CameraFaceResult *cameraFaceResult = [CameraFaceResult new];
//        [cameraFaceResult setBase64:self->_base64Center];
//        [cameraFaceResult setProcessId:processId];
//        [self.acessiBioManager onSuccesCameraFace:cameraFaceResult];
//
//        [self removeFlash];
//        [self doneProcess];
//
//    } failure:^(NSURLSessionTask *operation, NSError *error) {
//
//        self->isRequestWebService = NO;
//        self->isValidating = NO;
//
//        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
//        NSLog(@"%@",errResponse);
//
//        NSData *data = [errResponse dataUsingEncoding:NSUTF8StringEncoding];
//        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//
//        //[self resetSession];
//
//        if([json isKindOfClass:[NSDictionary class]]) {
//            NSDictionary *error = [json valueForKey:@"Error"];
//            NSString *description = [error valueForKey:@"Description"];
//            NSString *code = [NSString stringWithFormat:@"%lu", [[error valueForKey:@"Code"]integerValue]];
//            [self.acessiBioManager onErrorCameraFace:[self strErrorFormatted:@"createProcessV3" description:[NSString stringWithFormat:@"Code: %@ - %@", code, description ]]];
//        }else{
//            [self.acessiBioManager onErrorCameraFace:[self strErrorFormatted:@"createProcessV3" description:@"Verifique sua url de conexão, apikey e token. Se persistir, entre em contato com a equipe da Acesso."]];
//        }
//
//        [self exitError];
//
//
//    }];
    
    
}

- (void)showHUB {
//    HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
//    HUD.textLabel.text = @"Aguarde...";
//    [HUD showInView:self.view];
}

- (void)dismissHUB {
//    [HUD dismissAnimated:YES];
}


#pragma mark - FacesCompare

- (void)facesCompare: (NSString *)cpf base64: (NSString *)base64{
    
    [self showHUB];
    
    cpf = [cpf stringByReplacingOccurrencesOfString:@"." withString:@""];
    cpf = [cpf stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    AFJSONRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
//    
//    manager.requestSerializer = serializer;
//    [manager.requestSerializer setValue:self.APIKEY forHTTPHeaderField:@"APIKEY"];
//    [manager.requestSerializer setValue:self.TOKEN forHTTPHeaderField:@"Authorization"];
//    
//    NSDictionary *dict = @{
//        @"code": cpf,
//        @"imagebase64": base64
//    };
//    
//    NSString *strURL = [NSString stringWithFormat:@"%@/services/v3/AcessoService.svc/faces/compare", self.URL];
//    [manager POST:strURL parameters:dict headers:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
//        NSLog(@"JSON: %@", responseObject);
//        
//        [self dismissHUB];
//        
//        NSDictionary *dictresponse = responseObject;
//        
//        BOOL status = NO;
//        
//        if([[dictresponse valueForKey:@"Status"] integerValue] == 1) {
//            status = YES;
//        }
//        
//        [self.acessiBioManager onSuccessFacesCompare:status];
//        
//        [self removeFlash];
//        [self doneProcess];
//        
//    } failure:^(NSURLSessionTask *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//        
//        [self dismissHUB];
//        
//        NSString* errResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
//        NSLog(@"%@",errResponse);
//        
//        NSData *data = [errResponse dataUsingEncoding:NSUTF8StringEncoding];
//        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//        
//        if([json isKindOfClass:[NSDictionary class]]) {
//            NSDictionary *error = [json valueForKey:@"Error"];
//            NSString *description = [error valueForKey:@"Description"];
//            NSNumber * Code = [error valueForKey:@"Code"] ;
//            
//            [self.acessiBioManager onErrorFacesCompare:[self strErrorFormatted:@"facesCompare" description:[NSString stringWithFormat:@"Code: %@ - %@", Code, description ]]];
//            
//        }else{
//            [self.acessiBioManager onErrorFacesCompare:[self strErrorFormatted:@"facesCompare" description:@"Verifique sua url de conexão, apikey e token. Se persistir, entre em contato com a equipe da Acesso."]];
//        }
//        
//        [self exitError];
//     
//     }];
    
}


- (UIImage *)croppIngimage:(UIImage *)imageToCrop toRect:(CGRect)rect
{
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}

#pragma mark - Button Take Picture

- (void)addButtonTakePicture : (UIView *)view {
    self.btTakePic = [[UIButton alloc]initWithFrame:CGRectMake((SCREEN_WIDTH/2) - 40, SCREEN_HEIGHT - 100, 80, 80)];
    [self.btTakePic setImage:[UIImage imageNamed:@"icon_take_pic"] forState:UIControlStateNormal];
    [self.btTakePic addTarget:self action:@selector(capture) forControlEvents:UIControlEventTouchUpInside];
    if(_isEnableSmartCapture) {
        [self.btTakePic setAlpha:0.5];
        [self.btTakePic setEnabled:NO];
    }else{
        [self.btTakePic setAlpha:1.0];
        [self.btTakePic setEnabled:YES];
    }
    [self.view addSubview:self.btTakePic];
}

#pragma mark - Popup's

- (void)popupShow {
    
    isPopUpShow = YES;
    
    [vAlert setHidden:YES];
    [self removeFlash];
    
    [self addVHole:CGRectZero];
    
    popup = [[PopUpValidationLiveness alloc]initWithFrame:CGRectMake(((SCREEN_WIDTH/2) - 165), ((SCREEN_HEIGHT/2) - 180) , 330, 370)];
    [popup setType:PopupTypeGeneric faceInsertView:self];
    [popup setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:popup];
    
}

- (void)popupHidden {
    
    isPopUpShow = NO;
    
    [self changeHoleView:frameCurrent delayInSeconds:0];
    
    [popup removeFromSuperview];
    popup = nil;
    
}

#pragma mark - General

- (UIColor *)getColorPrimary {
    return [UIColor colorWithRed:41.0/255.0 green:128.0/255.0 blue:255.0/255.0 alpha:1.0];
}


- (UIColor *)getColorGreen {
    return [UIColor colorWithRed:59.0f/255.0f green:200.0f/255.0f blue:47.0f/255.0f alpha:1.0];
}


- (UIImage *)blurredImageWithImage:(UIImage *)sourceImage{
    
    //  Create our blurred image
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];
    
    //  Setting up Gaussian Blur
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:15.0f] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    
    /*  CIGaussianBlur has a tendency to shrink the image a little, this ensures it matches
     *  up exactly to the bounds of our original image */
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    
    UIImage *retVal = [UIImage imageWithCGImage:cgImage];
    
    if (cgImage) {
        CGImageRelease(cgImage);
    }
    
    return retVal;
}

- (void)exitError {
    [self invalidateAllTimers];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)strErrorFormatted: (NSString *)method description: (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %@", method, description];
}

@end
