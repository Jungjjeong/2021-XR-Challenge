// MARK: - Debug message viewer


import Foundation
import ARKit


enum MessageType {
	case trackingStateEscalation
	case planeEstimation
	case contentPlacement
	case focusSquare
}

class TextManager {

	init(viewController: MainViewController) {
		self.viewController = viewController
	}

	func showMessage(_ text: String, autoHide: Bool = true) {
		messageHideTimer?.invalidate() // 비활성화 및 루프에서 제거

		viewController.messageLabel.text = text
        // messageLabel -> show message

		showHideMessage(hide: false, animated: true)

		if autoHide {
			let charCount = text.count
			let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
			messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration,
			                                        repeats: false,
			                                        block: { [weak self] ( _ ) in
														self?.showHideMessage(hide: true, animated: true)
            // 타이머 생성(interval, repeats, block)
			})
		}
	}

	func showDebugMessage(_ message: String) {
		guard viewController.showDebugVisuals else {
			return
		} // showDebugVisuals -> 디버그 메세지 활성화 선택 (true)일 때.

		debugMessageHideTimer?.invalidate() // 비활성화 및 루프에서 제거

		viewController.debugMessageLabel.text = message
        // debugmessageLabel -> show debug message
        
		showHideDebugMessage(hide: false, animated: true)

		let charCount = message.count
		let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
		debugMessageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration,
		                                             repeats: false,
		                                             block: { [weak self] ( _ ) in
														self?.showHideDebugMessage(hide: true, animated: true)
		})
	}

	var schedulingMessagesBlocked = false

	func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
		// Do not schedule a new message if a feedback escalation alert is still on screen.
		guard !schedulingMessagesBlocked else {
			return
		}

		var timer: Timer?
		switch messageType {
		case .contentPlacement: timer = contentPlacementMessageTimer
		case .focusSquare: timer = focusSquareMessageTimer
		case .planeEstimation: timer = planeEstimationMessageTimer
		case .trackingStateEscalation: timer = trackingStateFeedbackEscalationTimer
		}

		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
		timer = Timer.scheduledTimer(withTimeInterval: seconds,
		                             repeats: false,
		                             block: { [weak self] ( _ ) in
										self?.showMessage(text)
										timer?.invalidate()
										timer = nil
		})
		switch messageType {
		case .contentPlacement: contentPlacementMessageTimer = timer
		case .focusSquare: focusSquareMessageTimer = timer
		case .planeEstimation: planeEstimationMessageTimer = timer
		case .trackingStateEscalation: trackingStateFeedbackEscalationTimer = timer
		}
	}

	func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
		showMessage(trackingState.presentationString, autoHide: autoHide)
	}

	func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
		if self.trackingStateFeedbackEscalationTimer != nil { // timer 초기화
			self.trackingStateFeedbackEscalationTimer!.invalidate()
			self.trackingStateFeedbackEscalationTimer = nil
		}

		self.trackingStateFeedbackEscalationTimer = Timer.scheduledTimer(withTimeInterval: seconds,
		                                                                 repeats: false, block: { _ in
			self.trackingStateFeedbackEscalationTimer?.invalidate()
			self.trackingStateFeedbackEscalationTimer = nil
			self.schedulingMessagesBlocked = true
			var title = ""
			var message = ""
			switch trackingState {
			case .notAvailable:
				title = "Tracking status: 사용할 수 없습니다. "
				message = "장기간에 Tracking status를 사용할 수 없습니다. 세선을 재설정해 주세요."
			case .limited(let reason):
				title = "Tracking status: 제한되었습니다."
				message = "장기간에 Tracking status 가 제한되었습니다. "
				switch reason {
				case .excessiveMotion: message += "움직임 속도를 낮추거나, 세션을 재설정해 주세요."
				case .insufficientFeatures: message += "평평한 표면을 가리키거나, 세션을 재설정해 주세요."
                case .initializing: message += "초기화."
                case .relocalizing: message += "평평한 표면을 가리키거나, 세션을 재설정해 주세요."
                }
			case .normal: break
			}

			let restartAction = UIAlertAction(title: "Reset", style: .destructive, handler: { _ in
				self.viewController.restartExperience(self)
				self.schedulingMessagesBlocked = false
			})
			let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
				self.schedulingMessagesBlocked = false
			})
			self.showAlert(title: title, message: message, actions: [restartAction, okAction])
		})
	}

	func cancelScheduledMessage(forType messageType: MessageType) {
		var timer: Timer?
		switch messageType {
		case .contentPlacement: timer = contentPlacementMessageTimer
		case .focusSquare: timer = focusSquareMessageTimer
		case .planeEstimation: timer = planeEstimationMessageTimer
		case .trackingStateEscalation: timer = trackingStateFeedbackEscalationTimer
		}

		if timer != nil {
			timer!.invalidate() // timer reset
			timer = nil
		}
	}

	func cancelAllScheduledMessages() {
		cancelScheduledMessage(forType: .contentPlacement)
		cancelScheduledMessage(forType: .planeEstimation)
		cancelScheduledMessage(forType: .trackingStateEscalation)
		cancelScheduledMessage(forType: .focusSquare)
	}

	var alertController: UIAlertController?

	func showAlert(title: String, message: String, actions: [UIAlertAction]? = nil) {
		alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		if let actions = actions {
			for action in actions {
				alertController!.addAction(action)
			}
		} else {
			alertController!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		}
		self.viewController.present(alertController!, animated: true, completion: nil)
	}

	func dismissPresentedAlert() {
		alertController?.dismiss(animated: true, completion: nil)
	}

	let blurEffectViewTag = 100

	func blurBackground() {
		let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
		let blurEffectView = UIVisualEffectView(effect: blurEffect)
		blurEffectView.frame = viewController.view.bounds
		blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		blurEffectView.tag = blurEffectViewTag
		viewController.view.addSubview(blurEffectView)
	}

	func unblurBackground() {
		for view in viewController.view.subviews {
			if let blurView = view as? UIVisualEffectView, blurView.tag == blurEffectViewTag {
				blurView.removeFromSuperview()
			}
		}
	}

	// MARK: - Private
	private var viewController: MainViewController!

	// Timers for hiding regular and debug messages
	private var messageHideTimer: Timer?
	private var debugMessageHideTimer: Timer?

	// Timers for showing scheduled messages
	private var focusSquareMessageTimer: Timer?
	private var planeEstimationMessageTimer: Timer?
	private var contentPlacementMessageTimer: Timer?

	// Timer for tracking state escalation
	private var trackingStateFeedbackEscalationTimer: Timer?

	private func showHideMessage(hide: Bool, animated: Bool) {
		if !animated {
			viewController.messageLabel.isHidden = hide
			return
		} // animation이 없으면, messagelabel hide

		UIView.animate(withDuration: 0.2, // (seconds)
		               delay: 0,
		               options: [.allowUserInteraction, .beginFromCurrentState],
		               animations: {
						self.viewController.messageLabel.isHidden = hide
						self.updateMessagePanelVisibility()
		}, completion: nil)
	} // animate( duration : timeinterval, animation : escaping )

	private func showHideDebugMessage(hide: Bool, animated: Bool) {
		if !animated {
			viewController.debugMessageLabel.isHidden = hide
			return
		} // animation이 없으면, debugmessageLabel hide -> hide의 값에 따라 변동 (bool)

		UIView.animate(withDuration: 0.2,
		               delay: 0,
		               options: [.allowUserInteraction, .beginFromCurrentState],
		               animations: {
						self.viewController.debugMessageLabel.isHidden = hide // animate 설정, hide 값 할당
						self.updateMessagePanelVisibility()
		}, completion: nil)
	}

	private func updateMessagePanelVisibility() {
		// Show and hide the panel depending whether there is something to show.
		viewController.messagePanel.isHidden = viewController.messageLabel.isHidden &&
			viewController.debugMessageLabel.isHidden &&
			viewController.featurePointCountLabel.isHidden
	} // 표시할 항목이 있는가에 따라 판넬을 보여주거나 숨긴다. 
}
