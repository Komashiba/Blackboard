Shader "Custom/Blackboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeStrength ("EdgeStrength", float) = 4.0
        _EdgeColor ("Edge Color", COLOR) = (1,1,1,1)
        _BoardColor ("Board Color", COLOR) = (0.2,0.35,0.23,1)
        _FillNoiseTex ("FillNoiseTexture", 2D) = "white" {}
        _NoiseStrength ("NoiseStrength", Range(0.0,1.0)) = 0.8
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _EdgeStrength;
            half4 _EdgeColor;
            half4 _BoardColor;
            sampler2D _FillNoiseTex;
			float _NoiseStrength;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
				// エッジ検出
                float2 duv = _MainTex_TexelSize.xy;

                half2 uv0 = i.uv + half2(-duv.x, -duv.y);
                half2 uv1 = i.uv + half2(duv.x, -duv.y);
                half2 uv2 = i.uv + half2(-duv.x, duv.y);
                half2 uv3 = i.uv + half2(duv.x, duv.y);

                half3 col0 = tex2D(_MainTex, uv0);
                half3 col1 = tex2D(_MainTex, uv1);
                half3 col2 = tex2D(_MainTex, uv2);
                half3 col3 = tex2D(_MainTex, uv3);
 
                float3 cg1 = col3 - col0;
                float3 cg2 = col2 - col1;
                float cg = sqrt(dot(cg1, cg1) + dot(cg2, cg2));
                half4 edge = cg * _EdgeStrength;

				// エッジの色
				fixed4 edge_col = _EdgeColor;
				edge_col.rgb = edge_col.rgb * edge;

				// ボードの色
				fixed4 board_col = _BoardColor;
				board_col.rgb = board_col.rgb * (1 - edge);

				// エッジの色とボードの色を混ぜる
				fixed4 chalk_col = edge_col + board_col;
				
				// 一定以上の明度がある場合は塗る
				float brightness_tex_color = tex2D(_MainTex, i.uv);
				// 元の画像を白黒にする
				fixed4 brightness_col = fixed4(brightness_tex_color, brightness_tex_color, brightness_tex_color, 1);
				fixed4 fill_noise_col = tex2D(_FillNoiseTex, i.uv);
				// ノイズ画像を減算で塗りつぶしにムラを作る
				fixed4 fill_col = saturate(brightness_col - (fill_noise_col + 1.0 - _NoiseStrength));

				// エッジとボードの色に加算
				chalk_col = chalk_col + fill_col;

				return chalk_col;				
            }
            ENDCG
        }
    }
	FallBack "Diffuse"
}