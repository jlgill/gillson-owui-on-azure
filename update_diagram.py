#!/usr/bin/env python3
diagram = '''<mxfile host="app.diagrams.net" modified="2024-01-15T10:00:00.000Z" agent="5.0" version="21.0.0" type="device">
  <diagram name="Open WebUI Architecture" id="architecture">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1000" pageHeight="560" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>

        <!-- ==================== TITLE ==================== -->
        <mxCell id="title" value="Open WebUI on Azure" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=18;fontStyle=1;fontColor=#333333;" vertex="1" parent="1">
          <mxGeometry x="25" y="15" width="280" height="26" as="geometry"/>
        </mxCell>
        <mxCell id="subtitle" value="Enterprise Architecture with Azure API Management" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontColor=#666666;" vertex="1" parent="1">
          <mxGeometry x="25" y="40" width="280" height="16" as="geometry"/>
        </mxCell>

        <!-- ==================== USER ==================== -->
        <mxCell id="user" value="" style="shape=image;verticalLabelPosition=bottom;labelBackgroundColor=default;verticalAlign=top;aspect=fixed;imageAspect=0;image=img/lib/azure2/general/User.svg;" vertex="1" parent="1">
          <mxGeometry x="35" y="195" width="40" height="40" as="geometry"/>
        </mxCell>
        <mxCell id="user_label" value="Users" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=9;fontColor=#333333;" vertex="1" parent="1">
          <mxGeometry x="25" y="238" width="60" height="14" as="geometry"/>
        </mxCell>

        <!-- ==================== HUB VNET ==================== -->
        <mxCell id="hub_vnet" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#E6F2FA;strokeColor=#0078D4;strokeWidth=2;arcSize=6;" vertex="1" parent="1">
          <mxGeometry x="110" y="70" width="260" height="350" as="geometry"/>
        </mxCell>
        <mxCell id="hub_label" value="Hub Virtual Network" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=10;fontStyle=1;fontColor=#0078D4;spacingLeft=8;spacingTop=5;" vertex="1" parent="1">
          <mxGeometry x="110" y="70" width="140" height="18" as="geometry"/>
        </mxCell>

        <!-- ==================== SPOKE VNET ==================== -->
        <mxCell id="spoke_vnet" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FFF4E5;strokeColor=#E67700;strokeWidth=2;arcSize=6;" vertex="1" parent="1">
          <mxGeometry x="400" y="70" width="280" height="155" as="geometry"/>
        </mxCell>
        <mxCell id="spoke_label" value="Spoke Virtual Network" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=10;fontStyle=1;fontColor=#E67700;spacingLeft=8;spacingTop=5;" vertex="1" parent="1">
          <mxGeometry x="400" y="70" width="150" height="18" as="geometry"/>
        </mxCell>

        <!-- VNet Peering -->
        <mxCell id="peering" value="" style="endArrow=classic;startArrow=classic;html=1;strokeWidth=1.5;strokeColor=#107C10;rounded=0;" edge="1" parent="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="370" y="147" as="sourcePoint"/>
            <mxPoint x="400" y="147" as="targetPoint"/>
          </mxGeometry>
        </mxCell>
        <mxCell id="peering_label" value="Peering" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=7;fontColor=#107C10;" vertex="1" parent="1">
          <mxGeometry x="355" y="155" width="45" height="12" as="geometry"/>
        </mxCell>

        <!-- ==================== APP GATEWAY SUBNET ==================== -->
        <mxCell id="appgw_subnet" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#0078D4;strokeWidth=1;dashed=1;arcSize=8;" vertex="1" parent="1">
          <mxGeometry x="125" y="95" width="115" height="85" as="geometry"/>
        </mxCell>
        <mxCell id="appgw_subnet_label" value="appgw-subnet" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=7;fontColor=#666666;spacingLeft=4;spacingTop=2;" vertex="1" parent="1">
          <mxGeometry x="125" y="95" width="70" height="12" as="geometry"/>
        </mxCell>

        <!-- Application Gateway -->
        <mxCell id="appgw" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/networking/Application_Gateways.svg;" vertex="1" parent="1">
          <mxGeometry x="155" y="115" width="48" height="48" as="geometry"/>
        </mxCell>
        <mxCell id="appgw_label" value="App Gateway" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#333333;" vertex="1" parent="1">
          <mxGeometry x="139" y="165" width="80" height="14" as="geometry"/>
        </mxCell>
        <mxCell id="step1" value="1" style="ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#107C10;strokeColor=none;fontColor=#FFFFFF;fontSize=9;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="125" y="93" width="18" height="18" as="geometry"/>
        </mxCell>

        <!-- ==================== APIM SUBNET ==================== -->
        <mxCell id="apim_subnet" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#0078D4;strokeWidth=1;dashed=1;arcSize=8;" vertex="1" parent="1">
          <mxGeometry x="125" y="195" width="115" height="95" as="geometry"/>
        </mxCell>
        <mxCell id="apim_subnet_label" value="apim-subnet" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=7;fontColor=#666666;spacingLeft=4;spacingTop=2;" vertex="1" parent="1">
          <mxGeometry x="125" y="195" width="60" height="12" as="geometry"/>
        </mxCell>

        <!-- API Management -->
        <mxCell id="apim" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/integration/API_Management_Services.svg;" vertex="1" parent="1">
          <mxGeometry x="155" y="218" width="48" height="44" as="geometry"/>
        </mxCell>
        <mxCell id="apim_label" value="API Management" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#333333;" vertex="1" parent="1">
          <mxGeometry x="130" y="265" width="100" height="14" as="geometry"/>
        </mxCell>
        <mxCell id="step3" value="3" style="ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#107C10;strokeColor=none;fontColor=#FFFFFF;fontSize=9;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="125" y="193" width="18" height="18" as="geometry"/>
        </mxCell>

        <!-- ==================== AZURE AI FOUNDRY ==================== -->
        <mxCell id="foundry_box" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#F3E5F5;strokeColor=#7B1FA2;strokeWidth=2;arcSize=8;" vertex="1" parent="1">
          <mxGeometry x="125" y="310" width="230" height="95" as="geometry"/>
        </mxCell>
        <mxCell id="foundry_label" value="Azure AI Services" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=10;fontStyle=1;fontColor=#7B1FA2;spacingLeft=8;spacingTop=5;" vertex="1" parent="1">
          <mxGeometry x="125" y="310" width="110" height="18" as="geometry"/>
        </mxCell>

        <!-- Azure AI Foundry -->
        <mxCell id="foundry" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/ai_machine_learning/Azure_OpenAI.svg;" vertex="1" parent="1">
          <mxGeometry x="215" y="340" width="44" height="44" as="geometry"/>
        </mxCell>
        <mxCell id="foundry_text" value="Azure AI Foundry" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#333333;" vertex="1" parent="1">
          <mxGeometry x="185" y="386" width="105" height="14" as="geometry"/>
        </mxCell>
        <mxCell id="step4" value="4" style="ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#107C10;strokeColor=none;fontColor=#FFFFFF;fontSize=9;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="125" y="308" width="18" height="18" as="geometry"/>
        </mxCell>

        <!-- ==================== ACA ENVIRONMENT ==================== -->
        <mxCell id="aca_subnet" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#E67700;strokeWidth=1;dashed=1;arcSize=8;" vertex="1" parent="1">
          <mxGeometry x="415" y="95" width="250" height="118" as="geometry"/>
        </mxCell>
        <mxCell id="aca_label" value="Container Apps Environment" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#666666;spacingLeft=4;spacingTop=2;" vertex="1" parent="1">
          <mxGeometry x="415" y="95" width="140" height="12" as="geometry"/>
        </mxCell>

        <!-- Container App -->
        <mxCell id="aca" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/containers/Container_Apps.svg;" vertex="1" parent="1">
          <mxGeometry x="515" y="125" width="44" height="38" as="geometry"/>
        </mxCell>
        <mxCell id="aca_text" value="Open WebUI" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=9;fontStyle=1;fontColor=#333333;" vertex="1" parent="1">
          <mxGeometry x="492" y="166" width="90" height="16" as="geometry"/>
        </mxCell>
        <mxCell id="step2" value="2" style="ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#107C10;strokeColor=none;fontColor=#FFFFFF;fontSize=9;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="415" y="93" width="18" height="18" as="geometry"/>
        </mxCell>

        <!-- ==================== SUPPORTING SERVICES ==================== -->
        <mxCell id="services_bg" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FAFAFA;strokeColor=#DDDDDD;strokeWidth=1;arcSize=8;" vertex="1" parent="1">
          <mxGeometry x="400" y="245" width="280" height="85" as="geometry"/>
        </mxCell>
        <mxCell id="services_label" value="Supporting Services" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#888888;spacingLeft=6;spacingTop=4;" vertex="1" parent="1">
          <mxGeometry x="400" y="245" width="90" height="14" as="geometry"/>
        </mxCell>

        <!-- Storage Account -->
        <mxCell id="storage" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/storage/Storage_Accounts.svg;" vertex="1" parent="1">
          <mxGeometry x="420" y="268" width="36" height="36" as="geometry"/>
        </mxCell>
        <mxCell id="storage_label" value="Storage" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=7;fontColor=#555555;" vertex="1" parent="1">
          <mxGeometry x="410" y="307" width="55" height="12" as="geometry"/>
        </mxCell>

        <!-- Key Vault -->
        <mxCell id="kv" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/security/Key_Vaults.svg;" vertex="1" parent="1">
          <mxGeometry x="490" y="268" width="36" height="36" as="geometry"/>
        </mxCell>
        <mxCell id="kv_label" value="Key Vault" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=7;fontColor=#555555;" vertex="1" parent="1">
          <mxGeometry x="478" y="307" width="60" height="12" as="geometry"/>
        </mxCell>

        <!-- Log Analytics -->
        <mxCell id="law" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/analytics/Log_Analytics_Workspaces.svg;" vertex="1" parent="1">
          <mxGeometry x="560" y="268" width="36" height="36" as="geometry"/>
        </mxCell>
        <mxCell id="law_label" value="Log Analytics" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=7;fontColor=#555555;" vertex="1" parent="1">
          <mxGeometry x="543" y="307" width="70" height="12" as="geometry"/>
        </mxCell>

        <!-- Entra ID -->
        <mxCell id="entra" value="" style="image;aspect=fixed;html=1;points=[];align=center;fontSize=12;image=img/lib/azure2/identity/Azure_Active_Directory.svg;" vertex="1" parent="1">
          <mxGeometry x="630" y="268" width="36" height="36" as="geometry"/>
        </mxCell>
        <mxCell id="entra_label" value="Entra ID" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=7;fontColor=#555555;" vertex="1" parent="1">
          <mxGeometry x="620" y="307" width="55" height="12" as="geometry"/>
        </mxCell>

        <!-- ==================== FLOW ARROWS ==================== -->

        <!-- User -> App Gateway -->
        <mxCell id="arrow1" value="" style="endArrow=blockThin;endFill=1;html=1;strokeWidth=2;strokeColor=#333333;rounded=0;" edge="1" parent="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="75" y="215" as="sourcePoint"/>
            <mxPoint x="155" y="139" as="targetPoint"/>
            <Array as="points">
              <mxPoint x="100" y="215"/>
              <mxPoint x="100" y="139"/>
            </Array>
          </mxGeometry>
        </mxCell>

        <!-- App Gateway -> Container App -->
        <mxCell id="arrow2" value="" style="endArrow=blockThin;endFill=1;html=1;strokeWidth=2;strokeColor=#333333;rounded=0;" edge="1" parent="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="203" y="139" as="sourcePoint"/>
            <mxPoint x="515" y="144" as="targetPoint"/>
            <Array as="points">
              <mxPoint x="260" y="139"/>
              <mxPoint x="260" y="60"/>
              <mxPoint x="490" y="60"/>
              <mxPoint x="490" y="144"/>
            </Array>
          </mxGeometry>
        </mxCell>

        <!-- Container App -> APIM -->
        <mxCell id="arrow3" value="" style="endArrow=blockThin;endFill=1;html=1;strokeWidth=2;strokeColor=#333333;rounded=0;" edge="1" parent="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="515" y="158" as="sourcePoint"/>
            <mxPoint x="203" y="240" as="targetPoint"/>
            <Array as="points">
              <mxPoint x="385" y="158"/>
              <mxPoint x="385" y="240"/>
            </Array>
          </mxGeometry>
        </mxCell>

        <!-- APIM -> Foundry -->
        <mxCell id="arrow4" value="" style="endArrow=blockThin;endFill=1;html=1;strokeWidth=2;strokeColor=#333333;rounded=0;" edge="1" parent="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="179" y="262" as="sourcePoint"/>
            <mxPoint x="215" y="340" as="targetPoint"/>
            <Array as="points">
              <mxPoint x="179" y="300"/>
              <mxPoint x="215" y="300"/>
            </Array>
          </mxGeometry>
        </mxCell>

        <!-- ==================== LEGEND ==================== -->
        <mxCell id="legend_box" value="" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#DDDDDD;strokeWidth=1;arcSize=8;" vertex="1" parent="1">
          <mxGeometry x="710" y="70" width="140" height="75" as="geometry"/>
        </mxCell>
        <mxCell id="legend_title" value="Legend" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=top;whiteSpace=wrap;rounded=0;fontSize=9;fontStyle=1;fontColor=#333333;spacingLeft=6;spacingTop=4;" vertex="1" parent="1">
          <mxGeometry x="710" y="70" width="45" height="14" as="geometry"/>
        </mxCell>
        <mxCell id="legend_arrow1" value="" style="endArrow=blockThin;endFill=1;html=1;strokeWidth=2;strokeColor=#333333;" edge="1" parent="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="722" y="98" as="sourcePoint"/>
            <mxPoint x="757" y="98" as="targetPoint"/>
          </mxGeometry>
        </mxCell>
        <mxCell id="legend_arrow1_label" value="Request flow" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#555555;" vertex="1" parent="1">
          <mxGeometry x="765" y="91" width="70" height="14" as="geometry"/>
        </mxCell>
        <mxCell id="legend_step" value="1" style="ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#107C10;strokeColor=none;fontColor=#FFFFFF;fontSize=8;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="727" y="110" width="16" height="16" as="geometry"/>
        </mxCell>
        <mxCell id="legend_step_label" value="Step number" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#555555;" vertex="1" parent="1">
          <mxGeometry x="765" y="110" width="65" height="14" as="geometry"/>
        </mxCell>
        <mxCell id="legend_peering" value="" style="endArrow=classic;startArrow=classic;html=1;strokeWidth=1.5;strokeColor=#107C10;" edge="1" parent="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="722" y="130" as="sourcePoint"/>
            <mxPoint x="757" y="130" as="targetPoint"/>
          </mxGeometry>
        </mxCell>
        <mxCell id="legend_peering_label" value="VNet peering" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=8;fontColor=#555555;" vertex="1" parent="1">
          <mxGeometry x="765" y="123" width="65" height="14" as="geometry"/>
        </mxCell>

        <!-- ==================== BRANDING ==================== -->
        <mxCell id="azure_logo" value="Microsoft Azure" style="text;html=1;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;whiteSpace=wrap;rounded=0;fontSize=10;fontStyle=1;fontColor=#0078D4;" vertex="1" parent="1">
          <mxGeometry x="25" y="425" width="100" height="16" as="geometry"/>
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>
</mxfile>'''

with open('/workspaces/azure-apim-openwebui-quickstart/docs/architecture.drawio', 'w') as f:
    f.write(diagram)
print("Done!")
