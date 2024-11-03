//
//  LottieView.swift
//  LevelMax
//
//  Created by 이승현 on 8/10/24.
//

import UIKit
import SwiftUI
import Lottie

class LottieAnimationViewWrapper: UIView {
    
    private let animationView: LottieAnimationView
    
    override init(frame: CGRect) {
        animationView = LottieAnimationView(name: "숫자")
        
        super.init(frame: frame)
        
        setupAnimationView()
        startAnimation() // 애니메이션을 초기화 시점에 자동으로 시작
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAnimationView() {
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        
        addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 200),
            animationView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    func startAnimation() {
        animationView.play()
    }
}

struct LottieAnimationViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> LottieAnimationViewWrapper {
        return LottieAnimationViewWrapper()
    }
    
    func updateUIView(_ uiView: LottieAnimationViewWrapper, context: Context) {
        
    }
}







