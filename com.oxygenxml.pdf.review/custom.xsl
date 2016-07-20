<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs saxon oxy"
    version="2.0"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:oxy="http://www.oxygenxml.com/extensions/author">
    <xsl:include href="review-utils.xsl"/>
    <xsl:param name="show.oxygen.changes.and.comments" select="'no'"/>
    
    <xsl:template match="text()">
        <xsl:choose>
            <xsl:when test="$show.oxygen.changes.and.comments = 'yes'">
                <!--  There is at least a comment/change tracking PI -->
                <xsl:variable name="typeAndPI" select="oxy:getHighlightState(.)"/>
                <!-- Start building the markup for comments, highlights -->
                <xsl:variable name="fragment">
                    <xsl:choose>
                        <xsl:when test="$typeAndPI[1] = 'insert'">
                            <fo:inline color="blue">
                                <xsl:copy/>
                            </fo:inline>
                            <xsl:call-template name="generateFootnote">
                                <xsl:with-param name="pi" select="$typeAndPI[2]"/>
                                <xsl:with-param name="color" select="'blue'"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$typeAndPI[1] = 'comment'">
                            <fo:inline background-color="yellow">
                                <xsl:copy/>
                            </fo:inline>
                            <xsl:call-template name="generateFootnote">
                                <xsl:with-param name="pi" select="$typeAndPI[2]"/>
                                <xsl:with-param name="color" select="'rgb(191, 191, 0)'"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="$typeAndPI[1] = 'highlight'">
                            <xsl:variable name="highlight-color">
                                <xsl:call-template name="get-pi-part">
                                    <xsl:with-param name="part" select="'color'"/>
                                    <xsl:with-param name="data" select="$typeAndPI[2]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <fo:inline background-color="rgb({$highlight-color})">
                                <xsl:copy/>
                            </fo:inline>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:copy-of select="$fragment"/>                
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="generateFootnote">
        <xsl:param name="pi"/>
        <xsl:param name="color"/>
        <xsl:variable name="commentContent">
            <xsl:apply-templates mode="getCommentContent" select="$pi"/>
        </xsl:variable>
        
        <xsl:if test="$commentContent != ''">
            <xsl:variable name="number">
                <xsl:number level="any" count="//processing-instruction()[
                    starts-with(name(), 'oxy_comment_start')
                    or starts-with(name(), 'oxy_insert_start')
                    or starts-with(name(), 'oxy_delete')
                    or starts-with(name(), 'oxy_attributes')
                    ][not(ancestor-or-self::opentopic:map)]" xmlns:opentopic="http://www.idiominc.com/opentopic"/>
            </xsl:variable>
            <xsl:variable name="fnid" select="generate-id($pi)"/>
            <fo:basic-link internal-destination="{$fnid}">
                <fo:footnote>
                    <fo:inline baseline-shift="super" font-size="75%" color="{$color}">[<xsl:value-of select="$number"/>]</fo:inline>
                    <fo:footnote-body>   
                        <fo:block color="{$color}" id="{$fnid}">     
                            <fo:inline baseline-shift="super" font-size="75%">
                                <xsl:value-of select="$number"/>
                            </fo:inline>
                            <fo:inline>
                                <xsl:copy-of select="$commentContent"/>
                            </fo:inline>                                           
                        </fo:block>
                    </fo:footnote-body>
                </fo:footnote>
            </fo:basic-link>
        </xsl:if>
    </xsl:template>
    
    
    <xsl:template mode="getCommentContent" match="processing-instruction()">
        <!-- Comment. -->
        <xsl:choose>
            <xsl:when test="name() = 'oxy_attributes'">
                <!-- Take each of the attribute changes (are separated with spaces.) -->
                <xsl:variable name="parsedAttrChange" select="oxy:attributesChangeAsNodeset(.)"/>
                <xsl:for-each select="$parsedAttrChange">
                    <xsl:value-of select="*:oxy-author"/>:&#160; <xsl:value-of select="@type"/> attr "<xsl:value-of select="@name"/>"
                    <xsl:if test="*:oxy-old-value">old value=</xsl:if><xsl:value-of select="*:oxy-old-value"/>&#160;
                    <xsl:if test="*:oxy-current-value">current value=</xsl:if><xsl:value-of select="*:oxy-current-value"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="comment-text">
                    <xsl:call-template name="get-pi-part">
                        <xsl:with-param name="part" select="'comment'"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- Author -->
                <xsl:variable name="author">
                    <xsl:call-template name="get-pi-part">
                        <xsl:with-param name="part" select="'author'"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="string-length($author) > 0">
                    <xsl:value-of select="$author"/>:&#160;
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="string-length($comment-text) > 0">
                        <xsl:value-of select="$comment-text" disable-output-escaping="yes"/>
                    </xsl:when>
                    <xsl:when test="starts-with(name(), 'oxy_insert')">
                        [Insertion]
                    </xsl:when>
                    <xsl:when test="starts-with(name(), 'oxy_delete')">
                        [Deletion]
                    </xsl:when>
                    <xsl:otherwise>
                        [Modification]
                    </xsl:otherwise>
                </xsl:choose>
                <!-- <!-\- Timestamp -\->
                    <xsl:variable name="timestamp">
                    <xsl:call-template name="get-pi-part">
                    <xsl:with-param name="part" select="'timestamp'"/>
                    </xsl:call-template>
                    </xsl:variable>
                    <xsl:if test="string-length($timestamp) > 0">
                    <fo:inline color="gray">
                    [<xsl:call-template name="get-date">
                    <xsl:with-param name="ts" select="$timestamp"/>
                    </xsl:call-template>&#160;<xsl:call-template name="get-hour">
                    <xsl:with-param name="ts" select="$timestamp"/>
                    </xsl:call-template>]
                    <!-\-<xsl:call-template name="get-tz">
                    <xsl:with-param name="ts" select="$timestamp"/>
                    </xsl:call-template>-\->
                    </fo:inline>
                    </xsl:if>-->
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- DELETE CHANGE, USE STRIKEOUT -->
    <xsl:template
        match="processing-instruction('oxy_delete')">
        <xsl:if test="$show.oxygen.changes.and.comments = 'yes'">
            <fo:inline color="red" text-decoration="line-through">
                <!-- We cannot parse the XML content back to nodes and apply templates
                because unfortunately the deleted content does not have class attribute values so it will not match any template.-->
                <xsl:value-of disable-output-escaping="yes">
                    <xsl:call-template name="get-pi-part">
                        <xsl:with-param name="part" select="'content'"/>
                    </xsl:call-template>
                </xsl:value-of>
            </fo:inline>    
            <xsl:call-template name="generateFootnote">
                <xsl:with-param name="pi" select="."/>
                <xsl:with-param name="color" select="'red'"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- ATTRIBUTE(S) CHANGE, USE FOOTNOTE -->
    <xsl:template
        match="processing-instruction('oxy_attributes')">
        <xsl:if test="$show.oxygen.changes.and.comments = 'yes'">
            <xsl:call-template name="generateFootnote">
                <xsl:with-param name="pi" select="."/>
                <xsl:with-param name="color" select="'blue'"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>