package com.example.love_day_counter

import io.flutter.embedding.android.FlutterFragmentActivity

// QUAN TRỌNG: package local_auth cần Activity host là FragmentActivity để
// gắn BiometricPrompt vào. Trước đây MainActivity kế thừa FlutterActivity
// (không phải FragmentActivity), nên gọi LocalAuthentication.authenticate()
// trên Android sẽ ném lỗi/không hiện được hộp thoại vân tay — đây chính là
// nguyên nhân gốc của lỗi "PIN & vân tay thường xuyên bị lỗi".
class MainActivity : FlutterFragmentActivity()
