//
//  SupabaseConfig.swift
//  Moovie
//
//  Created by Claude Code on 4/9/26.
//

import Foundation

struct SupabaseConfig {
    /// Supabase project URL
    static let url: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            fatalError("SUPABASE_URL not found in Info.plist. Make sure Secrets.xcconfig is properly configured.")
        }
        return url
    }()

    /// Supabase anonymous/publishable key (safe for client-side use, protected by RLS)
    static let anonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist. Make sure Secrets.xcconfig is properly configured.")
        }
        return key
    }()
}
