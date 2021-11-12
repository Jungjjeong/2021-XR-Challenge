// MARK: - ARCamera를 사용했을 시, 품질이 좋지 않은 경우 -> return


import Foundation
import ARKit


extension ARCamera.TrackingState {
	var presentationString: String {
		switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "TRACKING LIMITED\n카메라의 흔들림이 큽니다."
            case .insufficientFeatures:
                return "TRACKING LIMITED\n표면 정보가 부족합니다."
            case .initializing:
                return "초기화"
            case .relocalizing:
                return "초기화"
            }
        }
	}
}
