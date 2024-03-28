//
//  Settings.swift
//  ISM_App
//

import Foundation
import SwiftUI

struct ColorSchemeModifier: ViewModifier {
    @AppStorage("selectedAppearance") var selectedAppearance = 0
    var colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        switch selectedAppearance {
        case 1:
            return content.preferredColorScheme(.light)
        case 2:
            return content.preferredColorScheme(.dark)
        default:
            return content.preferredColorScheme(nil)
        }
    }
}
