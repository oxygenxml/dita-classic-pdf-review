<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs saxon oxy"
    version="2.0"
    xmlns:oxy="http://www.oxygenxml.com/extensions/author"
    xmlns:saxon="http://saxon.sf.net/">
    <!-- Converts a timestamp to a date using the YYYY/MM/DD format -->
    <xsl:template name="get-date">
        <xsl:param name="ts"/>
        <xsl:value-of select="substring($ts, 1, 4)"/>/<xsl:value-of select="substring($ts, 5, 2)"
        />/<xsl:value-of select="substring($ts, 7, 2)"/>
    </xsl:template>
    
    <!-- Converts a timestamp to a string containing hours, minutes, seconds. -->
    <xsl:template name="get-hour">
        <xsl:param name="ts"/>
        <xsl:variable name="part" select="substring-after($ts, 'T')"/>
        <xsl:value-of select="substring($part, 1,2)"/>:<xsl:value-of select="substring($part, 3,2)"/>:<xsl:value-of select="substring($part,5,2)"/>
    </xsl:template>
    
    <!-- Converts a timestamp to a timezone. -->
    <xsl:template name="get-tz">
        <xsl:param name="ts"/>        
        <xsl:variable name="part" select="substring-after($ts, 'T')"/>
        <xsl:choose>
            <xsl:when test="contains($part,'+')">                
                <xsl:variable name="t" select="substring-after($part, '+')"/>
                <xsl:variable name="t1" select="concat(substring($t, 1, 2), ':', substring($t, 3, 2))"/>                
                <xsl:value-of select="concat('+', $t1)"/>                
            </xsl:when>
            <xsl:when test="contains($part,'-')">
                <xsl:variable name="t" select="substring-after($part, '-')"/>
                <xsl:variable name="t1" select="concat(substring($t, 1, 2), ':', substring($t, 3, 2))"/>
                <xsl:value-of select="concat('-', $t1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'+00:00'"/>                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- Gets a part from the comment PI. -->
    <xsl:template name="get-pi-part">
        <xsl:param name="part"/>
        <xsl:param name="data" select="."/>
        <xsl:variable name="after" select="substring-after($data, concat($part, '=&quot;'))"/>
        <xsl:variable name="before" select="substring-before($after, '&quot;')"/>
        <xsl:value-of select="$before"/>
    </xsl:template>
    
    <xsl:function name="oxy:unescape" as="xs:string">
        <xsl:param name="in" as="xs:string"/>
        <xsl:variable name="s2" select="replace($in, '&amp;amp;', '&amp;')"/>
        <xsl:variable name="s3" select="replace($s2, '&amp;lt;', '&lt;')"/>
        <xsl:variable name="s4" select="replace($s3, '&amp;gt;', '&gt;')"/>
        <xsl:variable name="s5" select="replace($s4, '&amp;quot;', '&quot;')"/>
        <xsl:variable name="s6" select="replace($s5,'&amp;apos;', &quot;&apos;&quot;)"/>
        <xsl:value-of select="$s6"/>
    </xsl:function>
    
    <xsl:template match="attribute" mode="attributes-changes">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="change" mode="attributes-changes">
        <xsl:param name="ctx" tunnel="yes"/>
        <xsl:variable name="aName" select="../@name"/>
        <oxy:oxy-attribute-change type="{@type}" name="{$aName}">
            <oxy:oxy-author>
                <xsl:value-of select="@author"/>
            </oxy:oxy-author>
            <xsl:if test="@comment">
                <oxy:oxy-comment-text>
                    <xsl:value-of select="@comment"/>
                </oxy:oxy-comment-text>
            </xsl:if>
            <xsl:if test="@oldValue">
                <oxy:oxy-old-value>
                    <xsl:value-of select="@oldValue"/>
                </oxy:oxy-old-value>
            </xsl:if>
            <xsl:variable name="currentValue" select="$ctx/@*[local-name() = $aName]"/>
            <xsl:if test="$currentValue">
                <oxy:oxy-current-value>
                    <xsl:choose>
                        <xsl:when test="$aName = 'id'">
                            <!-- DITA OT is rewriting the values from the @id attribute, so there is no point in showing them.-->
                            <xsl:attribute name="unknown" select="'true'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$currentValue"/>                        
                        </xsl:otherwise>
                    </xsl:choose>
                </oxy:oxy-current-value>
            </xsl:if>
        </oxy:oxy-attribute-change>
    </xsl:template>
    
    <xsl:function name="oxy:getHighlightState" as="item()*">
        <xsl:param name="context" as="node()"/>
        
        <!--  There is at least a comment/change tracking PI -->
        <!-- Highlight the inserts -->
        <xsl:variable name="preceding-insert"
            select="$context/preceding::processing-instruction()
            [name() = 'oxy_insert_start' or name() = 'oxy_insert_end']"/>
        <xsl:variable name="is-in-insert"
            select="$preceding-insert[last()]/name() = 'oxy_insert_start'"/>
        
        <!--  The highlight is not perfect, it fails on nested comments. -->
        <xsl:variable name="preceding-comment"
            select="$context/preceding::processing-instruction()
            [name() = 'oxy_comment_start' or name() = 'oxy_comment_end']"/>
        
        <xsl:variable name="is-in-comment"
            select="$preceding-comment[last()]/name() = 'oxy_comment_start'"/>
        
        
        <!-- The highlight is not perfect, it fails on nested highlights. -->
        <xsl:variable name="preceding-highlight"
            select="$context/preceding::processing-instruction()
            [(name() = 'oxy_custom_start' and contains(., 'type=&quot;oxy_content_highlight&quot;')) 
            or name() = 'oxy_custom_end']"/>
        
        <xsl:variable name="is-in-highlight"
            select="$context/$preceding-highlight[last()]/name() = 'oxy_custom_start'"/>
        
        <xsl:choose>
            <xsl:when test="$is-in-insert">
                <xsl:sequence select="'insert', $preceding-insert[last()]"/>
            </xsl:when>
            <xsl:when test="$is-in-comment">
                <xsl:sequence select="'comment', $preceding-comment[last()]"/>
            </xsl:when>
            <xsl:when test="$is-in-highlight">
                <xsl:sequence select="'highlight', $preceding-highlight[last()]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'other'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- Convert an attributes PI to a node set. -->
    <xsl:function name="oxy:attributesChangeAsNodeset" as="item()*">
        <xsl:param name="attributesPI" as="node()"/>
        <!-- Take each of the attribute changes (are separated with spaces.) -->
        <xsl:variable name="s1"
            select="replace($attributesPI, '\s*(.*?)=&quot;(.*?)&quot;', '&amp;lt;attribute name=&quot;$1&quot;&amp;gt;$2&amp;lt;/attribute&amp;gt;')"/>
        <xsl:apply-templates
            select="saxon:parse(concat('&lt;root>', oxy:unescape($s1), '&lt;/root>'))"
            mode="attributes-changes">
            <!-- In order to access the current attributes values -->
            <xsl:with-param name="ctx" select="$attributesPI/following-sibling::*[1]" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:function>
</xsl:stylesheet>