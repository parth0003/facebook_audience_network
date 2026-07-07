import Foundation
import Flutter
import FBAudienceNetwork

class FacebookAudienceNetworkRewardedVideoAdPlugin: NSObject, FBRewardedVideoAdDelegate {
    let channel: FlutterMethodChannel
    var rewardedVideoAd: FBRewardedVideoAd?

    init(_channel: FlutterMethodChannel) {
        channel = _channel

        super.init()

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "loadRewardedAd":
                result(self.loadAd(call))
            case "showRewardedAd":
                result(self.showAd(call))
            case "destroyRewardedAd":
                result(self.destroyAd())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func loadAd(_ call: FlutterMethodCall) -> Bool {
        let args = call.arguments as! NSDictionary
        let id = args["id"] as! String

        if rewardedVideoAd == nil || rewardedVideoAd?.isAdValid == false {
            rewardedVideoAd = FBRewardedVideoAd(placementID: id)
            rewardedVideoAd?.delegate = self
        }

        rewardedVideoAd?.load()
        return true
    }

    func showAd(_ call: FlutterMethodCall) -> Bool {
        guard let rewardedVideoAd = rewardedVideoAd, rewardedVideoAd.isAdValid else {
            return false
        }

        let args = call.arguments as! NSDictionary
        let delay = args["delay"] as! Int
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController

        if delay > 0 {
            let time = DispatchTime.now() + .milliseconds(delay)
            DispatchQueue.main.asyncAfter(deadline: time) {
                guard let rewardedVideoAd = self.rewardedVideoAd, rewardedVideoAd.isAdValid else {
                    return
                }
                rewardedVideoAd.show(fromRootViewController: rootViewController)
            }
        } else {
            rewardedVideoAd.show(fromRootViewController: rootViewController)
        }

        return true
    }

    func destroyAd() -> Bool {
        guard rewardedVideoAd != nil else {
            return false
        }

        rewardedVideoAd?.delegate = nil
        rewardedVideoAd = nil
        return true
    }

    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        let arg: [String: Any] = [
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: !rewardedVideoAd.isAdValid,
        ]
        channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: arg)
    }

    func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        let nsError = error as NSError
        let arg: [String: Any] = [
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: !rewardedVideoAd.isAdValid,
            "error_code": nsError.code,
            "error_message": nsError.localizedDescription,
        ]
        channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: arg)
    }

    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        let arg: [String: Any] = [
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: !rewardedVideoAd.isAdValid,
        ]
        channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: arg)
    }

    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        let arg: [String: Any] = [
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: !rewardedVideoAd.isAdValid,
        ]
        channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: arg)
    }

    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        channel.invokeMethod(FANConstant.REWARDED_VIDEO_COMPLETE_METHOD, arguments: true)
    }

    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        channel.invokeMethod(FANConstant.REWARDED_VIDEO_CLOSED_METHOD, arguments: true)
    }
}
