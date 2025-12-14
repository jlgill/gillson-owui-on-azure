
import os

# Define the XML content with Azure icons and better styling
xml_content = """<mxfile host="Electron" modified="2025-12-14T12:10:00.000Z" agent="GitHub Copilot" version="21.6.8" type="device">
  <diagram id="Architecture" name="Architecture">
    <mxGraphModel dx="1422" dy="794" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1100" pageHeight="850" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <!-- Styles -->
        <!-- We will use inline styles for simplicity in this generated file -->

        <!-- ==================== ZONES ==================== -->

        <!-- Azure Subscription / Outer Box -->
        <mxCell id="sub" value="Azure Subscription" style="swimlane;html=1;startSize=20;horizontal=1;container=1;collapsible=0;rounded=0;arcSize=10;fillColor=none;strokeColor=#0078D4;strokeWidth=2;dashed=1;fontColor=#0078D4;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="120" y="40" width="880" height="680" as="geometry" />
        </mxCell>

        <!-- Hub VNet -->
        <mxCell id="hub_vnet" value="Hub VNet" style="swimlane;html=1;startSize=20;horizontal=1;container=1;collapsible=0;rounded=1;arcSize=10;fillColor=#F0F7FF;strokeColor=#0078D4;fontColor=#0078D4;" vertex="1" parent="sub">
          <mxGeometry x="40" y="60" width="300" height="580" as="geometry" />
        </mxCell>

        <!-- Spoke VNet -->
        <mxCell id="spoke_vnet" value="Spoke VNet" style="swimlane;html=1;startSize=20;horizontal=1;container=1;collapsible=0;rounded=1;arcSize=10;fillColor=#FFF8F0;strokeColor=#FF8C00;fontColor=#FF8C00;" vertex="1" parent="sub">
          <mxGeometry x="400" y="60" width="440" height="580" as="geometry" />
        </mxCell>

        <!-- ==================== SUBNETS ==================== -->

        <!-- AppGw Subnet -->
        <mxCell id="snet_appgw" value="AppGw Subnet" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#DEEBF7;strokeColor=none;align=left;verticalAlign=top;spacingLeft=5;fontColor=#666666;fontSize=11;" vertex="1" parent="hub_vnet">
          <mxGeometry x="20" y="40" width="260" height="140" as="geometry" />
        </mxCell>

        <!-- APIM Subnet -->
        <mxCell id="snet_apim" value="APIM Subnet" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#DEEBF7;strokeColor=none;align=left;verticalAlign=top;spacingLeft=5;fontColor=#666666;fontSize=11;" vertex="1" parent="hub_vnet">
          <mxGeometry x="20" y="220" width="260" height="140" as="geometry" />
        </mxCell>

        <!-- ACA Subnet -->
        <mxCell id="snet_aca" value="ACA Subnet" style="rounded=0;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=none;align=left;verticalAlign=top;spacingLeft=5;fontColor=#666666;fontSize=11;" vertex="1" parent="spoke_vnet">
          <mxGeometry x="20" y="40" width="400" height="360" as="geometry" />
        </mxCell>

        <!-- ==================== RESOURCES ==================== -->

        <!-- User -->
        <mxCell id="user" value="User" style="shape=mxgraph.azure2.general.user;html=1;fillColor=#0078D4;strokeColor=none;verticalLabelPosition=bottom;verticalAlign=top;align=center;" vertex="1" parent="1">
          <mxGeometry x="20" y="160" width="47" height="50" as="geometry" />
        </mxCell>

        <!-- App Gateway -->
        <mxCell id="appgw" value="Application Gateway&#xa;(WAF)" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/networking/Application_Gateways.svg;" vertex="1" parent="snet_appgw">
          <mxGeometry x="98" y="40" width="64" height="64" as="geometry" />
        </mxCell>

        <!-- APIM -->
        <mxCell id="apim" value="API Management" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/integration/API_Management_Services.svg;" vertex="1" parent="snet_apim">
          <mxGeometry x="98" y="40" width="65" height="60" as="geometry" />
        </mxCell>

        <!-- ACA Environment -->
        <mxCell id="aca_env" value="Container Apps Environment" style="group" vertex="1" connectable="0" parent="snet_aca">
            <mxGeometry x="40" y="40" width="320" height="280" as="geometry" />
        </mxCell>
        <mxCell id="aca_env_bg" value="Container Apps Env" style="rounded=1;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#d6b656;dashed=1;verticalAlign=top;align=left;spacingLeft=10;fontColor=#d6b656;" vertex="1" parent="aca_env">
            <mxGeometry width="320" height="280" as="geometry" />
        </mxCell>

        <!-- Open WebUI ACA -->
        <mxCell id="aca_app" value="Open WebUI" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/compute/Container_Apps.svg;" vertex="1" parent="aca_env">
          <mxGeometry x="128" y="60" width="64" height="64" as="geometry" />
        </mxCell>

        <!-- Storage -->
        <mxCell id="storage" value="Storage Account&#xa;(Files)" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/storage/Storage_Accounts.svg;" vertex="1" parent="spoke_vnet">
          <mxGeometry x="60" y="460" width="65" height="52" as="geometry" />
        </mxCell>

        <!-- Key Vault -->
        <mxCell id="kv" value="Key Vault" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/security/Key_Vaults.svg;" vertex="1" parent="spoke_vnet">
          <mxGeometry x="200" y="460" width="68" height="68" as="geometry" />
        </mxCell>

        <!-- Foundry -->
        <mxCell id="foundry" value="Azure AI Foundry" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/ai_machine_learning/Azure_AI_Services.svg;" vertex="1" parent="sub">
          <mxGeometry x="140" y="500" width="68" height="68" as="geometry" />
        </mxCell>

        <!-- Entra ID -->
        <mxCell id="entra" value="Microsoft Entra ID" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/identity/Azure_Active_Directory.svg;" vertex="1" parent="1">
          <mxGeometry x="920" y="200" width="70" height="64" as="geometry" />
        </mxCell>

        <!-- Monitor -->
        <mxCell id="monitor" value="Azure Monitor" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/monitor/Monitor.svg;" vertex="1" parent="1">
          <mxGeometry x="920" y="400" width="64" height="64" as="geometry" />
        </mxCell>

        <!-- ==================== EDGES ==================== -->

        <!-- 1. User -> AppGw -->
        <mxCell id="e1" value="1. HTTPS" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeColor=#000000;strokeWidth=2;" edge="1" parent="1" source="user" target="appgw">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>

        <!-- 2. AppGw -> ACA -->
        <mxCell id="e2" value="2. HTTPS (Internal)" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeColor=#000000;strokeWidth=2;" edge="1" parent="1" source="appgw" target="aca_app">
          <mxGeometry relative="1" as="geometry">
            <Array as="points">
              <mxPoint x="380" y="172" />
              <mxPoint x="380" y="232" />
            </Array>
          </mxGeometry>
        </mxCell>

        <!-- 3. ACA -> APIM -->
        <mxCell id="e3" value="3. OpenAI API" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=1;entryY=0.5;entryDx=0;entryDy=0;strokeColor=#000000;strokeWidth=2;" edge="1" parent="1" source="aca_app" target="apim">
          <mxGeometry relative="1" as="geometry">
            <Array as="points">
              <mxPoint x="600" y="350" />
            </Array>
          </mxGeometry>
        </mxCell>

        <!-- 4. APIM -> Foundry -->
        <mxCell id="e4" value="4. Proxy" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0.5;entryY=0;entryDx=0;entryDy=0;strokeColor=#000000;strokeWidth=2;" edge="1" parent="1" source="apim" target="foundry">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>

        <!-- 5. ACA -> Storage -->
        <mxCell id="e5" value="Mount" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0.5;entryY=0;entryDx=0;entryDy=0;dashed=1;strokeColor=#666666;" edge="1" parent="1" source="aca_app" target="storage">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>

        <!-- 6. ACA -> KV -->
        <mxCell id="e6" value="Secrets" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0.5;entryY=0;entryDx=0;entryDy=0;dashed=1;strokeColor=#666666;" edge="1" parent="1" source="aca_app" target="kv">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>

        <!-- 7. ACA -> Entra -->
        <mxCell id="e7" value="OIDC Auth" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;dashed=1;strokeColor=#666666;" edge="1" parent="1" source="aca_app" target="entra">
          <mxGeometry relative="1" as="geometry">
             <Array as="points">
                <mxPoint x="600" y="232" />
             </Array>
          </mxGeometry>
        </mxCell>

        <!-- 8. Monitor -->
        <mxCell id="e8" value="Logs/Metrics" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;dashed=1;strokeColor=#666666;" edge="1" parent="1" source="aca_app" target="monitor">
          <mxGeometry relative="1" as="geometry">
             <Array as="points">
                <mxPoint x="600" y="432" />
             </Array>
          </mxGeometry>
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>
</mxfile>"""

with open('/workspaces/azure-apim-openwebui-quickstart/docs/architecture.drawio', 'w') as f:
    f.write(xml_content)
