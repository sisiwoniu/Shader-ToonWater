Shader "CustomShader/ToonWaterSurface"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Noise("Noise Tex", 2D) = "white" {}
		_Tint("Tint", Color) = (1, 1, 1, 1)
		_Speed("Wave Speed", Range(0, 1)) = 0.5
		_NoiseSp("Noise Wave Speed", Range(0, 1)) = 0.5
		_Amount("Wave Amount", Range(0, 1)) = 0.5
		_Height("Wave Height", Range(0, 1)) = 0.5
		_Foam("Foamline Thickness", Range(0, 3)) = 0.5
		_Scale("Scale", Range(0, 0.5)) = 0.1
		_RippleSize("RippleSize", Range(1, 3)) = 1.5
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        
		LOD 100

		Blend SrcAlpha OneMinusSrcAlpha

		Cull off

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
				float4 srcPos : TECOORD1;
				float4 worldPos : TECOORD2;
            };

            sampler2D _MainTex;
			sampler2D _Noise;
			sampler2D _CameraDepthTexture;
			fixed4 _Tint;
			half _Speed, _NoiseSp;
			half _Amount;
			half _Height;
			half _Foam;
			half _Scale;
			half _RippleSize;
			float3 _Position;
			sampler2D _GlobalEffectRT;
			float _OrthographicCamSize;

            v2f vert (appdata v)
            {
                v2f o;

				//波作る前にワールド座標を取っておく
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				//波作る
				v.vertex.y += sin(_Time.z * _Speed + (v.vertex.x * v.vertex.z * _Amount)) * _Height;

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;

				//頂点のスクリーンスペースの位置を取る
				o.srcPos = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed distortx = tex2D(_Noise, (i.uv.xy * _Scale) + _Time.x * _NoiseSp).r;
				
				i.uv.x += distortx;

				i.uv.y += distortx;

                fixed4 col = tex2D(_MainTex, i.uv) * _Tint;

				half depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, i.srcPos));

				half4 foamLine = 1 - saturate(_Foam * (depth - i.srcPos.w));

				//ripples
				float2 ripplesUV = i.worldPos.xz - _Position.xz;

				ripplesUV = ripplesUV / (_OrthographicCamSize * 2);

				ripplesUV += 0.5;

				float ripples = tex2D(_GlobalEffectRT, ripplesUV).b;

				col += foamLine * _Tint + step(0.99, ripples * _RippleSize);

                return col;
            }
            ENDCG
        }
    }
}
